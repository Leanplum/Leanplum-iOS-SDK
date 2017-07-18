//
//  RequestStorageTest.m
//  Leanplum-SDK-Tests
//
//  Created by Alexis Oyama on 5/30/17.
//  Copyright © 2017 Leanplum. All rights reserved.
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


#import <XCTest/XCTest.h>
#import <OHHTTPStubs/OHHTTPStubs.h>
#import <OHHTTPStubs/OHPathHelpers.h>
#import "LeanplumHelper.h"
#import "LeanplumRequest+Categories.h"
#import "Constants.h"
#import "LPRequestStorage.h"
#import "LPNetworkEngine+Category.h"
#import "LeanplumReachability+Category.h"
#import "LPJSON.h"

/**
 * Expose private class methods
 */
@interface LPRequestStorage(UnitTest)

- (void)migrateRequests;
- (void)saveRequests:(NSMutableArray *)requests;
- (NSMutableArray *)loadRequests;
- (NSString *)cacheFilePath;
- (NSString *)documentsFilePath;
+ (NSString *)itemKeyForIndex:(NSUInteger)index;

@end

@interface RequestStorageTest : XCTestCase

@property (strong, nonatomic) NSFileManager *fileManager;
@property (strong, nonatomic) LPRequestStorage *requestStorage;
@property (strong, nonatomic) NSUserDefaults *userDefaults;

@end

@implementation RequestStorageTest

- (void)setUp {
    [super setUp];
    self.fileManager = [NSFileManager defaultManager];
    self.requestStorage = [LPRequestStorage sharedStorage];
    self.userDefaults = [NSUserDefaults standardUserDefaults];
    [LeanplumHelper setup_method_swizzling];
    [LeanplumHelper start_production_test];
    
    if ([self.fileManager fileExistsAtPath:self.requestStorage.documentsFilePath]) {
        [self.fileManager removeItemAtPath:self.requestStorage.documentsFilePath error:nil];
    }
    if ([self.fileManager fileExistsAtPath:self.requestStorage.cacheFilePath]) {
        [self.fileManager removeItemAtPath:self.requestStorage.cacheFilePath error:nil];
    }
}

- (void)tearDown {
    [super tearDown];
    [LeanplumHelper clean_up];
}

- (NSDictionary *)sampleData
{
    return @{@"action":@"track", @"deviceId":@"123", @"userId":@"QA_TEST", @"client":@"ios",
             @"sdkVersion":@"3", @"devMode":@NO, @"time":@"1489007921.162919"};
}

- (void)test_migrateRequest
{
    // Save requests to cache.
    NSError *error = nil;
    NSData *requestData = [NSPropertyListSerialization dataWithPropertyList:@[[self sampleData]]
                                                                     format:NSPropertyListBinaryFormat_v1_0
                                                                    options:0
                                                                      error:&error];
    XCTAssertFalse(error);
    XCTAssertTrue(requestData);
    [requestData writeToFile:self.requestStorage.cacheFilePath atomically:YES];
    XCTAssertTrue([self.fileManager fileExistsAtPath:self.requestStorage.cacheFilePath]);

    // Check migration from cache to documents.
    [self.requestStorage migrateRequests];
    XCTAssertFalse([self.fileManager fileExistsAtPath:self.requestStorage.cacheFilePath]);
    XCTAssertTrue([self.fileManager fileExistsAtPath:self.requestStorage.documentsFilePath]);
    
    // Save requests to NSUserDefault.
    [self.fileManager removeItemAtPath:self.requestStorage.documentsFilePath error:nil];
    [self.userDefaults setObject:@3 forKey:LEANPLUM_DEFAULTS_COUNT_KEY];
    for (NSInteger i = 0; i < 3; i++) {
        NSString *itemKey = [LPRequestStorage itemKeyForIndex:i];
        [self.userDefaults setObject:[self sampleData] forKey:itemKey];
    }
    [self.userDefaults synchronize];
    
    // Check migration from NSUserDefault to documents.
    [self.requestStorage migrateRequests];
    XCTAssertTrue([self.fileManager fileExistsAtPath:self.requestStorage.documentsFilePath]);
    NSArray *requests = [self.requestStorage loadRequests];
    XCTAssertTrue(requests.count == 3);
}

- (void)test_pushAndPop
{
    // Check push.
    [self.requestStorage pushRequest:[self sampleData]];
    [self.requestStorage pushRequest:[self sampleData]];
    XCTAssertTrue([self.fileManager fileExistsAtPath:self.requestStorage.documentsFilePath]);
    NSArray *requests = [self.requestStorage loadRequests];
    XCTAssertTrue(requests.count == 2);
    
    // Check multiple push.
    NSMutableArray *sampleDatas = [NSMutableArray new];
    for (int i = 0; i < 5; i++) {
        [sampleDatas addObject:[self sampleData]];
    }
    [self.requestStorage pushRequests:sampleDatas];
    XCTAssertTrue([self.fileManager fileExistsAtPath:self.requestStorage.documentsFilePath]);
    requests = [self.requestStorage loadRequests];
    XCTAssertTrue(requests.count == 7);
    
    // Check pop.
    requests = [self.requestStorage popAllRequests];
    XCTAssertTrue(requests.count == 7);
    XCTAssertFalse([self.fileManager fileExistsAtPath:self.requestStorage.documentsFilePath]);
}

- (void)test_push_10k
{
    NSMutableArray *sampleDatas = [NSMutableArray new];
    for (int i = 0; i < 10100; i++) {
        [sampleDatas addObject:[self sampleData]];
    }
    [self.requestStorage pushRequests:sampleDatas];
    NSArray *requests = [self.requestStorage popAllRequests];
    XCTAssertTrue(requests.count == 10000);
    
}

@end
