//
//  LPRequestStorage.m
//  Leanplum
//
//  Created by Andrew First on 10/23/14.
//  Copyright (c) 2014 Leanplum, Inc. All rights reserved.
//
//  Licensed to the Apache Software Foundation (ASF) under one
//  or more contributor license agreements.  See the NOTICE file
//  distributed with this work for additional information
//  regarding copyright ownership.  The ASF licenses this file
//  to you under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing,
//  software distributed under the License is distributed on an
//  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
//  KIND, either express or implied.  See the License for the
//  specific language governing permissions and limitations
//  under the License.

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
        [self migrateRequests];
    }
    return self;
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
        NSInteger count = [_defaults integerForKey:LEANPLUM_DEFAULTS_COUNT_KEY];
        if (count) {
            for (NSInteger i = 0; i < count; i++) {
                NSString *itemKey = [LPRequestStorage itemKeyForIndex:i];
                NSDictionary *requestArgs = [_defaults dictionaryForKey:itemKey];
                if (requestArgs) {
                    [requests addObject:requestArgs];
                }
                [_defaults removeObjectForKey:itemKey];
            }
            [_defaults removeObjectForKey:LEANPLUM_DEFAULTS_COUNT_KEY];
            [_defaults synchronize];
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
    if (requests.count > MAX_STORED_API_CALLS) {
        NSRange range = NSMakeRange(requests.count - MAX_STORED_API_CALLS, MAX_STORED_API_CALLS);
        requests = [[requests subarrayWithRange:range] mutableCopy];
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
