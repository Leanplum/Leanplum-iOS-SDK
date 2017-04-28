//
//  LPRequestStorage.m
//  Leanplum
//
//  Created by Andrew First on 10/23/14.
//
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
        _defaults = [NSUserDefaults standardUserDefaults];
        _requests = [self loadRequests];
    }
    return self;
}

- (NSMutableArray *)loadRequests
{
    NSMutableArray *requests = [NSMutableArray array];
    @synchronized (self) {
        // For compatibility with older SDKs.
        // TODO: Remove in April 2015.
        NSInteger count = [_defaults integerForKey:LEANPLUM_DEFAULTS_COUNT_KEY];
        for (NSInteger i = 0; i < count; i++) {
            NSString* itemKey = [LPRequestStorage itemKeyForIndex:i];
            NSDictionary* requestArgs = [_defaults dictionaryForKey:itemKey];
            if (requestArgs != nil) {
                [requests addObject:requestArgs];
            }
        }

        if (!count) {
            // Backwards compatible with old cached directory
            NSError *error;
            if ([[NSFileManager defaultManager] fileExistsAtPath:self.cacheFilePath]) {
                [[NSFileManager defaultManager] moveItemAtPath:self.cacheFilePath
                                                        toPath:self.documentsFilePath
                                                         error:&error];
                if (error) {
                    LPLog(LPVerbose, @"Error in moving stored requests: %@", error);
                }
            }
            NSData *requestData = [NSData dataWithContentsOfFile:self.documentsFilePath];
            if (requestData) {
                error = nil;
                NSMutableArray *savedRequests = [NSPropertyListSerialization
                                                 propertyListWithData:requestData
                                                 options:NSPropertyListMutableContainers
                                                 format:NULL error:&error];
                if (savedRequests) {
                    requests = savedRequests;
                }
            }
        }
    }

    LPLog(LPDebug, @"Loaded %lu requests", (unsigned long) requests.count);

    return requests;
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

- (void)saveRequests
{
    NSArray *requestsCopy;
    @synchronized (self) {
        requestsCopy = [_requests copy];
    }
    if (requestsCopy.count > MAX_STORED_API_CALLS) {
        NSRange range = NSMakeRange(requestsCopy.count - MAX_STORED_API_CALLS,
          MAX_STORED_API_CALLS);
        requestsCopy = [[requestsCopy subarrayWithRange:range] mutableCopy];
    }

    NSError *error = nil;
    NSData *requestData = [NSPropertyListSerialization dataWithPropertyList:requestsCopy
      format:NSPropertyListBinaryFormat_v1_0 options:0 error:&error];
    if (requestData) {
        [requestData writeToFile:[self documentsFilePath] atomically:YES];
    } else {
        [[NSFileManager defaultManager] removeItemAtPath:[self documentsFilePath] error:&error];
    }

    LPLog(LPDebug, @"Saved %lu requests", (unsigned long) requestsCopy.count);
}

+ (LPRequestStorage *)sharedStorage
{
    static LPRequestStorage *_sharedStorage = nil;
    static dispatch_once_t sharedStorageToken;
    dispatch_once(&sharedStorageToken, ^{
        _sharedStorage = [[self alloc] init];
    });
    return _sharedStorage;
}

// For compatibility with older SDKs.
// TODO: Remove in April 2015.
+ (NSString *)itemKeyForIndex:(NSUInteger)index
{
    return [NSString stringWithFormat:LEANPLUM_DEFAULTS_ITEM_KEY, index];
}

- (void)pushRequest:(NSDictionary *)requestData
{
    @synchronized (self) {
        [_requests addObject:requestData];
    }
}

- (NSArray *)popAllRequests
{
    NSArray *result = _requests;
    @synchronized (self) {
        _requests = [NSMutableArray array];
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

        // For compatibility with older SDKs.
        // TODO: Remove in April 2015.
        NSInteger count = [_defaults integerForKey:LEANPLUM_DEFAULTS_COUNT_KEY];
        if (count > 0) {
            [_defaults removeObjectForKey:LEANPLUM_DEFAULTS_COUNT_KEY];
            for (NSInteger i = 0; i < count; i++) {
                NSString* itemKey = [LPRequestStorage itemKeyForIndex:i];
                [_defaults removeObjectForKey:itemKey];
            }
            [_defaults synchronize];
        }

    }
    return result;
}

@end
