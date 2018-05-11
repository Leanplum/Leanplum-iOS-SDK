//
//  LPRequestStorage.m
//  Leanplum
//
//  Copyright (c) 2018 Leanplum, Inc. All rights reserved.
//

#import "LPRequestStorage.h"
#import "Constants.h"
#import "LeanplumInternal.h"
#import "LPFileManager.h"
#import "LeanplumRequest.h"

@implementation LPRequestStorage

- (id)init
{
    if (self = [super init]) {
        [self migrateRequests];
    }
    return self;
}

+ (LPRequestStorage *)sharedStorage
{
    static LPRequestStorage *_sharedStorage = nil;
    static dispatch_once_t sharedStorageToken;
    dispatch_once(&sharedStorageToken, ^{
        _sharedStorage = [self new];
    });
    return _sharedStorage;
}

/**
 * Handle migration from old saving methods. 
 * List of migrations:
 * 1) Moving away from NSUserDefaults. iOS8 introduced a performance hit that made it
 * unusable. Introduced saving to file as plist. Safe to remove from April 2015.
 * 2) Previously it was saving to the cache directory. Moving it to documents. (1.5.0)
 */
- (void)migrateRequests
{
    @synchronized (self) {
        // Move old cached directory to documents directory.
        NSError *error;
        if ([[NSFileManager defaultManager] fileExistsAtPath:self.cacheFilePath]) {
            [[NSFileManager defaultManager] moveItemAtPath:self.cacheFilePath
                                                    toPath:self.documentsFilePath
                                                     error:&error];
            if (error) {
                LPLog(LPVerbose, @"Error in moving stored requests: %@", error);
            }
        }
        
        // For compatibility with older SDKs.
        NSMutableArray *requests = [NSMutableArray array];
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSInteger count = [defaults integerForKey:LEANPLUM_DEFAULTS_COUNT_KEY];
        if (count) {
            for (NSInteger i = 0; i < count; i++) {
                NSString *itemKey = [LPRequestStorage itemKeyForIndex:i];
                NSDictionary *requestArgs = [defaults dictionaryForKey:itemKey];
                if (requestArgs) {
                    [requests addObject:requestArgs];
                }
                [defaults removeObjectForKey:itemKey];
            }
            [defaults removeObjectForKey:LEANPLUM_DEFAULTS_COUNT_KEY];
            [defaults synchronize];
            if (![[NSFileManager defaultManager] fileExistsAtPath:self.documentsFilePath]) {
                [self saveRequests:requests];
            }
        }
    }
}

/**
 * Save requests to documents directory as a plist format.
 * Make sure to wrap this call with synchronize to support multi-threaded cases.
 */
- (void)saveRequests:(NSMutableArray *)requests
{
    if (requests.count > MAX_EVENTS_PER_API_CALL) {
        NSRange range = NSMakeRange(0, requests.count - MAX_EVENTS_PER_API_CALL);
        [requests removeObjectsInRange:range];
    }
    
    NSError *error = nil;
    NSData *requestData = [NSPropertyListSerialization dataWithPropertyList:requests
                                                                     format:NSPropertyListBinaryFormat_v1_0
                                                                    options:0
                                                                      error:&error];
    if (requestData) {
        [requestData writeToFile:[self documentsFilePath] atomically:YES];
        LPLog(LPDebug, @"Saved %lu requests", (unsigned long) requests.count);
    } else {
        [[NSFileManager defaultManager] removeItemAtPath:[self documentsFilePath] error:&error];
        if (error) {
            LPLog(LPDebug, @"Error in saving requests: %@", error);
        }
    }
}

/**
 * Load requests from the plist in documents directory.
 * Make sure to wrap this call with synchronize to support multi-threaded cases.
 */
- (NSMutableArray *)loadRequests
{
    NSData *requestData = [NSData dataWithContentsOfFile:self.documentsFilePath];
    if (requestData) {
        NSError *error = nil;
        NSMutableArray *requests = [NSPropertyListSerialization
                                         propertyListWithData:requestData
                                         options:NSPropertyListMutableContainers
                                         format:NULL error:&error];
        if (error) {
            LPLog(LPDebug, @"Error in loading requets: %@", error);
        } else {
            LPLog(LPDebug, @"Loaded %lu requests", (unsigned long) requests.count);
        }
        
        return requests;
    }
    
    return [NSMutableArray new];
}

/**
 * This is deprecated. Previously we save everything in the cache directory.
 * This is meant for files and not important data such as requests.
 */
- (NSString *)cacheFilePath
{
    return [[LPFileManager cachesDirectory] stringByAppendingPathComponent:
            [NSString stringWithFormat:@"_lprequests-%@", LeanplumRequest.appId]];
}

/**
 * This file path returns the one in documents directory. Requests should be stored here.
 * It will be synced in iCloud and the data will not be lost.
 */
- (NSString *)documentsFilePath
{
    return [[LPFileManager documentsDirectory] stringByAppendingPathComponent:
            [NSString stringWithFormat:@"_lprequests-%@", LeanplumRequest.appId]];
}

/** 
 * Returns the item key for requests data that is used in NSUserDefault.
 * This is here to be compatible with the older SDKS. 
 * Safe to remove from April 2015.
 */
+ (NSString *)itemKeyForIndex:(NSUInteger)index
{
    return [NSString stringWithFormat:LEANPLUM_DEFAULTS_ITEM_KEY, index];
}

#pragma mark Public Methods

- (void)pushRequest:(NSDictionary *)requestData
{
    @synchronized (self) {
        NSMutableArray *requests = [self loadRequests];
        [requests addObject:requestData];
        [self saveRequests:requests];
    }
}

- (void)pushRequests:(NSArray *)requestDatas
{
    @synchronized (self) {
        NSMutableArray *requests = [self loadRequests];
        [requests addObjectsFromArray:requestDatas];
        [self saveRequests:requests];
    }
}

- (NSArray *)popAllRequests
{
    NSMutableArray *requests;
    @synchronized (self) {
        requests = [self loadRequests];
        _lastSentTime = [NSDate timeIntervalSinceReferenceDate];

        NSError *error;
        if ([[NSFileManager defaultManager] removeItemAtPath:[self documentsFilePath]
                                                       error:&error]) {
            if (error) {
                LPLog(LPVerbose, @"Error in deleting stored requests: %@", error);
            } else {
                LPLog(LPDebug, @"Deleted stored requests.");
            }
        }
    }
    return requests;
}

@end
