//
//  LPRequestSenderTest.m
//  Leanplum-SDK_Tests
//
//  Created by Grace Gu on 10/01/18.
//  Copyright © 2018 Leanplum. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import <Leanplum/LPEventDataManager.h>
#import <Leanplum/LPRequestSender.h>
#import <Leanplum/LPRequestFactory.h>
#import <Leanplum/LPRequest.h>

@interface LPRequestSender(UnitTest)


@end

@interface LPRequestSenderTest : XCTestCase

@end

@implementation LPRequestSenderTest

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testSendEventually {
    LPRequest *request = [LPRequest post:@"test" params:@{}];
    //id<LPRequesting> request =
    LPRequestSender *requestSender = [[LPRequestSender alloc] init];
    //LPRequestFactory *reqFactory = [[LPRequestFactory alloc]
    //                                initWithFeatureFlagManager:[LPFeatureFlagManager sharedManager]];
    //id<LPRequesting> request = [reqFactory startWithParams:@{}];
    NSString *uuid = @"uuid";
    [[NSUserDefaults standardUserDefaults] setObject:uuid forKey:LEANPLUM_DEFAULTS_UUID_KEY];
    
    NSMutableDictionary *args = [requestSender createArgsDictionaryForRequest:request];
    args[LP_PARAM_UUID] = uuid;
    
    id eventDataManagerMock = OCMClassMock([LPEventDataManager class]);

    //[requestSender sendNow:request];
    [requestSender sendEventually:request];
    OCMVerify([eventDataManagerMock addEvent:[OCMArg isNotNil]]);
}


@end
