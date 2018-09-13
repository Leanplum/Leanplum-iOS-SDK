//
//  AppIconManagerTest.m
//  Leanplum-SDK
//
//  Created by Grace Gu on 9/11/18.
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
#import "LPCountAggregator.h"

/**
 * Expose private class methods
 */
@interface LPCountAggregator(UnitTest)

@property (nonatomic, strong) NSMutableDictionary *counts;

@end

@interface LPCountAggregatorTest : XCTestCase

@end

@implementation LPCountAggregatorTest

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)test_incrementDisabledCount {
    LPCountAggregator *countAggregator = [[LPCountAggregator alloc] init];
    NSString *testString = @"test";

    [countAggregator incrementCount:testString];
    XCTAssert([countAggregator.counts[testString] intValue] == 0);
    
    [countAggregator incrementCount:testString];
    XCTAssert([countAggregator.counts[testString] intValue] == 0);
}

- (void)test_incrementCount {
    LPCountAggregator *countAggregator = [[LPCountAggregator alloc] init];
    NSString *testString = @"test";
    countAggregator.enabledCounters = [NSSet setWithObjects:testString, nil];
    
    [countAggregator incrementCount:testString];
    XCTAssert([countAggregator.counts[testString] intValue] == 1);
    
    [countAggregator incrementCount:testString];
    XCTAssert([countAggregator.counts[testString] intValue] == 2);
    
}

- (void)test_incrementDisabledCountMultiple {
    LPCountAggregator *countAggregator = [[LPCountAggregator alloc] init];
    NSString *testString = @"test";
    
    [countAggregator incrementCount:testString by:2];
    XCTAssert([countAggregator.counts[testString] intValue] == 0);
    
    [countAggregator incrementCount:testString by:15];
    XCTAssert([countAggregator.counts[testString] intValue] == 0);
}

- (void)test_incrementCountMultiple {
    LPCountAggregator *countAggregator = [[LPCountAggregator alloc] init];
    NSString *testString = @"test";
    countAggregator.enabledCounters = [NSSet setWithObjects:testString, nil];
    
    [countAggregator incrementCount:testString by:2];
    XCTAssert([countAggregator.counts[testString] intValue] == 2);
    
    [countAggregator incrementCount:testString by:15];
    XCTAssert([countAggregator.counts[testString] intValue] == 17);
}

@end
