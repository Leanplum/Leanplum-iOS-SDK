//
//  LPRequestSenderTimerTest.m
//  Leanplum-SDK_Tests
//
//  Created by Dejan Krstevski on 12/16/20.
//  Copyright © 2020 Leanplum. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "LPRequestSenderTimer.h"
#import "NSTimer+Blocks.h"
//#import "LeanplumHelper.h"

@interface LPRequestSenderTimerTest : XCTestCase

@end

@implementation LPRequestSenderTimerTest

- (void)setUp
{
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testDefaultTimerIsSetTo15Min
{
    XCTAssertTrue([LPRequestSenderTimer sharedInstance].timerInterval == AT_MOST_15_MINUTES);
}

- (void)testStartTimerWillFireForTimeInterval
{
    LPRequestSenderTimer *timer = [LPRequestSenderTimer sharedInstance];
    [timer setTimerInterval:AT_MOST_5_MINUTES];
    NSTimeInterval heartbeatInterval = timer.timerInterval; //testing in sec
    XCTestExpectation *timerExpectation = [self expectationWithDescription:@"timerExpectation"];
    [LPTimerBlocks scheduledTimerWithTimeInterval:heartbeatInterval block:^() {
        [timerExpectation fulfill];
    } repeats:NO];
    
    [self waitForExpectationsWithTimeout:6 handler:nil];
    
}

@end
