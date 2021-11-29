//
//  EventDataManagerTest.m
//  Leanplum-SDK-Tests
//
//  Created by Alexis Oyama on 6/13/17.
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
#import <OCMock/OCMock.h>
#import <OHHTTPStubs/HTTPStubs.h>
#import <OHHTTPStubs/HTTPStubsPathHelpers.h>
#import "LeanplumHelper.h"
#import "Leanplum+Extensions.h"
#import <Leanplum/LPEventDataManager.h>
#import <Leanplum/LPDatabase.h>
#import <Leanplum/LPConstants.h>
#import "LPRequestFactory+Extension.h"
#import "LPRequestSender+Categories.h"
#import "LPNetworkEngine+Category.h"
#import "LeanplumReachability+Category.h"
#import <Leanplum/LPJSON.h>
#import <Leanplum/LPOperationQueue.h>
#import <Leanplum/LPNetworkConstants.h>

@interface LPEventDataManager(UnitTest)

+ (void)migrateRequests;

@end

@interface LPEventDataManagerTest : XCTestCase

@end

@implementation LPEventDataManagerTest

- (void)setUp {
    [super setUp];
    id mockedDB = OCMClassMock([LPDatabase class]);
    OCMStub([mockedDB sqliteFilePath]).andReturn(@":memory:");
    [LeanplumHelper setup_method_swizzling];
    [LeanplumHelper start_production_test];
    [LPNetworkEngine setupValidateOperation];
    [Leanplum_Reachability online:YES];
}

- (void)tearDown {
    [super tearDown];
    [LeanplumHelper clean_up];
    [HTTPStubs removeAllStubs];
}

- (NSDictionary *)sampleData
{
    return @{@"action":@"track", @"deviceId":@"123", @"userId":@"QA_TEST", @"client":@"ios",
             @"sdkVersion":@"3", @"devMode":@NO, @"time":@"1489007921.162919"};
}

- (void)test_publicEventMethods
{
    [LPEventDataManager deleteEventsWithLimit:10000];

    // Add Event.
    [LPEventDataManager addEvent:[self sampleData]];
    NSArray *events = [LPEventDataManager eventsWithLimit:10000];
    XCTAssertTrue(events.count == 1);

    [LPEventDataManager addEvent:[self sampleData]];
    events = [LPEventDataManager eventsWithLimit:10000];
    XCTAssertTrue(events.count == 2);

    // Add Multiple Events.
    NSMutableArray *mulitpleEvents = [NSMutableArray new];
    for (int i=0; i<5; i++) {
        [mulitpleEvents addObject:[self sampleData]];
    }
    [LPEventDataManager addEvents:mulitpleEvents];
    events = [LPEventDataManager eventsWithLimit:10000];
    XCTAssertTrue(events.count == 7);

    // Get Events with limit.
    events = [LPEventDataManager eventsWithLimit:2];
    XCTAssertTrue(events.count == 2);

    // Delete events with limit.
    [LPEventDataManager deleteEventsWithLimit:3];
    events = [LPEventDataManager eventsWithLimit:10000];
    XCTAssertTrue(events.count == 4);

    // Delete the rest.
    [LPEventDataManager deleteEventsWithLimit:10000];
    events = [LPEventDataManager eventsWithLimit:10000];
    XCTAssertTrue(events.count == 0);
}

- (void)test_track_save
{
    [LPEventDataManager deleteEventsWithLimit:10000];

    [Leanplum track:@"sample"];
    [[LPOperationQueue serialQueue] waitUntilAllOperationsAreFinished];
    NSArray *events = [LPEventDataManager eventsWithLimit:10000];
    XCTAssertTrue(events.count == 1);

    [Leanplum track:@"sample2"];
    [[LPOperationQueue serialQueue] waitUntilAllOperationsAreFinished];
    events = [LPEventDataManager eventsWithLimit:10000];
    XCTAssertTrue(events.count == 2);
}

- (void)test_response_code
{
    [LeanplumHelper clean_up];
    [LeanplumHelper setup_production_test];
    [LPEventDataManager deleteEventsWithLimit:10000];

    // Simulate error from http response code.
    [HTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [request.URL.host isEqualToString:API_HOST];;
    } withStubResponse:^HTTPStubsResponse * _Nonnull(NSURLRequest * _Nonnull request) {
        NSData *data = [@"Fail" dataUsingEncoding:NSUTF8StringEncoding];
        return [HTTPStubsResponse responseWithData:data statusCode:500 headers:nil];
    }];

    NSArray *events = [LPEventDataManager eventsWithLimit:10000];
    XCTAssertTrue(events.count == 0);

    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    [LPNetworkEngine validate_operation:^BOOL(LPNetworkOperation *operation) {
        dispatch_semaphore_signal(semaphore);
        return YES;
    }];

    LPRequest *request = [[LPRequestFactory createPostForApiMethod:@"sample3" params:nil] andRequestType:Immediate];
    [[LPRequestSender sharedInstance] send:request];
    long timedOut = dispatch_semaphore_wait(semaphore, [LeanplumHelper default_dispatch_time]);
    XCTAssertTrue(timedOut == 0);
    events = [LPEventDataManager eventsWithLimit:10000];
    XCTAssertTrue(events.count == 1);

    [HTTPStubs removeAllStubs];
}

- (void)test_uuid
{
    [LPEventDataManager deleteEventsWithLimit:10000];

    // Create a stub for track event response.
    [HTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest * _Nonnull request) {
        return [request.URL.host isEqualToString:API_HOST];
    } withStubResponse:^HTTPStubsResponse * _Nonnull(NSURLRequest * _Nonnull request) {
        NSString *response_file = OHPathForFile(@"track_event_response.json", self.class);
        return [HTTPStubsResponse responseWithFileAtPath:response_file statusCode:200
                                                   headers:@{@"Content-Type":@"application/json"}];
    }];

    // UUID should be the same.
    [Leanplum track:@"sample"];
    [Leanplum track:@"sample2"];
    [[LPOperationQueue serialQueue] waitUntilAllOperationsAreFinished];

    // Should have same uuids.
    NSArray *events = [LPEventDataManager eventsWithLimit:10000];
    XCTAssertTrue(events.count == 2);
    XCTAssertTrue([events[0][@"uuid"] isEqual:events[1][@"uuid"]]);
    NSString *oldUUID = events[0][@"uuid"];
    [Leanplum forceContentUpdate];

    // After sending, the last one should have a different uuid.
    [Leanplum track:@"sample4"];
    [[LPOperationQueue serialQueue] waitUntilAllOperationsAreFinished];
    events = [LPEventDataManager eventsWithLimit:10000];
    XCTAssertTrue(events.count == 1);
    XCTAssertFalse([events[0][@"uuid"] isEqual:oldUUID]);

    // No events should be stored.
    [Leanplum forceContentUpdate];
    [[LPOperationQueue serialQueue] waitUntilAllOperationsAreFinished];
    events = [LPEventDataManager eventsWithLimit:10000];
    XCTAssertTrue(events.count == 0);

    // UUID should be different after the 10k mark.
    for (int i=0; i<LP_MAX_EVENTS_PER_API_CALL+1; i++) {
        [Leanplum track:@"s"];
    }
    [[LPOperationQueue serialQueue] waitUntilAllOperationsAreFinished];
    events = [LPEventDataManager eventsWithLimit:900000];
    XCTAssertTrue(events.count == LP_MAX_EVENTS_PER_API_CALL+1);
    XCTAssertFalse([events[0][@"uuid"] isEqual:events[LP_MAX_EVENTS_PER_API_CALL][@"uuid"]]);

    // Make sure there will be 2 requests that are split because of MAX_EVENTS_PER_API_CALL.
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    NSInteger __block requestCount = 0;
    [LPNetworkEngine validate_operation:^(LPNetworkOperation *operation) {
        requestCount++;
        if (requestCount == 1) {
            return NO;
        }
        dispatch_semaphore_signal(semaphore);
        return YES;
    }];
    [Leanplum forceContentUpdate];
    [[LPOperationQueue serialQueue] waitUntilAllOperationsAreFinished];

    long timedOut = dispatch_semaphore_wait(semaphore, [LeanplumHelper default_dispatch_time]);
    XCTAssertTrue(timedOut == 0);
    XCTAssertTrue(requestCount == 2);
}

- (void)test_response_index
{
    [LPEventDataManager deleteEventsWithLimit:10000];

    [HTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [request.URL.host isEqualToString:API_HOST];
    } withStubResponse:^HTTPStubsResponse * _Nonnull(NSURLRequest * _Nonnull request) {
        NSString *response_file = OHPathForFile(@"batch_response.json", self.class);
        return [HTTPStubsResponse responseWithFileAtPath:response_file statusCode:200
                                                   headers:@{@"Content-Type":@"application/json"}];
    }];

    // Make sure there are 3 events to send.
    XCTestExpectation *operationExpectation =
    [self expectationWithDescription:@"operationExpectation"];
    [LPNetworkEngine validate_operation:^(LPNetworkOperation *operation) {
        NSArray *events = [LPEventDataManager eventsWithLimit:900000];
        XCTAssertTrue(events.count == 1);
        [operationExpectation fulfill];
        return YES;
    }];

    // Queue up the events and test if the callback is in the correct index.
    XCTestExpectation *responseExpectation =
    [self expectationWithDescription:@"responseExpectation"];
    LPRequest *request = [[LPRequestFactory createPostForApiMethod:@"test2" params:nil] andRequestType:Immediate];
    [request onResponse:^(id<LPNetworkOperationProtocol> operation, id json) {
        // Make sure the response is the first one.
        XCTAssertTrue([json[@"index"] intValue] == 1);
        [responseExpectation fulfill];
    }];
    [[LPRequestSender sharedInstance] send:request];
    [[LPOperationQueue serialQueue] waitUntilAllOperationsAreFinished];


    // Add extra events.
    [Leanplum track:@"s"];
    [Leanplum track:@"s2"];
    [[LPOperationQueue serialQueue] waitUntilAllOperationsAreFinished];

    [self waitForExpectationsWithTimeout:2 handler:nil];
}

@end
