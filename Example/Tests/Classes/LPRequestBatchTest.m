//
//  LPRequestBatchTest.m
//  Leanplum-SDK_Tests
//
//  Copyright © 2020 Leanplum. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import <OHHTTPStubs/HTTPStubs.h>
#import <OHHTTPStubs/HTTPStubsPathHelpers.h>
#import "LeanplumHelper.h"
#import "LPDatabase.h"
#import "LPRequestBatch.h"
#import "LPRequestBatchFactory.h"
#import "LPEventDataManager.h"
#import "LPNetworkConstants.h"
#import "LPOperationQueue.h"

@interface LPRequestBatchTest : XCTestCase

@end

@implementation LPRequestBatchTest

- (void)setUp
{
    // Put setup code here. This method is called before the invocation of each test method in the class.
    id mockedDB = OCMClassMock([LPDatabase class]);
    OCMStub([mockedDB sqliteFilePath]).andReturn(@":memory:");
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [LeanplumHelper clean_up];
    [HTTPStubs removeAllStubs];
}

- (NSDictionary *)sampleData
{
    return @{@"action":@"track", @"deviceId":@"123", @"userId":@"QA_TEST", @"client":@"ios",
             @"sdkVersion":@"3", @"devMode":@NO, @"time":@"1489007921.162919"};
}

- (void)testGetEventsCount
{
    [LPEventDataManager deleteEventsWithLimit:LP_MAX_EVENTS_PER_API_CALL];
    
    LPRequestBatch *testBatch = [LPRequestBatchFactory createNextBatch];
    XCTAssertTrue([testBatch getEventsCount] == 0);
    
    [LPEventDataManager addEvent:[self sampleData]];
    testBatch = [LPRequestBatchFactory createNextBatch];
    XCTAssertTrue([testBatch getEventsCount] == 1);
    
    [LPEventDataManager addEvent:[self sampleData]];
    testBatch = [LPRequestBatchFactory createNextBatch];
    XCTAssertTrue([testBatch getEventsCount] == 2);
    
    [LPRequestBatchFactory deleteFinishedBatch:testBatch];
}

- (void)testBatchIsEmpty
{
    [LPEventDataManager deleteEventsWithLimit:LP_MAX_EVENTS_PER_API_CALL];
    
    LPRequestBatch *testBatch = [LPRequestBatchFactory createNextBatch];
    XCTAssertTrue([testBatch isEmpty]);
    
    [LPEventDataManager addEvent:[self sampleData]];
    testBatch = [LPRequestBatchFactory createNextBatch];
    XCTAssertFalse([testBatch isEmpty]);
    
    [LPRequestBatchFactory deleteFinishedBatch:testBatch];
}

- (void)testBatchIsFull
{
    [LPEventDataManager deleteEventsWithLimit:LP_MAX_EVENTS_PER_API_CALL];
    
    LPRequestBatch *testBatch = [LPRequestBatchFactory createNextBatch];
    XCTAssertFalse([testBatch isFull]);
    
    for (int i = 0; i < LP_MAX_EVENTS_PER_API_CALL; i++) {
        [LPEventDataManager addEvent:[self sampleData]];
    }
    
    testBatch = [LPRequestBatchFactory createNextBatch];
    XCTAssertTrue([testBatch isFull]);
    [LPRequestBatchFactory deleteFinishedBatch:testBatch];
}

@end
