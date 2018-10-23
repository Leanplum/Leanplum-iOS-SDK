//
//  LPRequestSenderTest.m
//  Leanplum-SDK_Tests
//
//  Created by Grace Gu on 10/01/18.
//  Copyright © 2018 Leanplum. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import <Leanplum/LPAPIConfig.h>
#import <Leanplum/LPEventDataManager.h>
#import <Leanplum/LPNetworkProtocol.h>
#import <Leanplum/LPRequestSender.h>
#import <Leanplum/LPRequestFactory.h>
#import <Leanplum/LPRequest.h>
#import <Leanplum/LPCountAggregator.h>

@interface LPRequestSender(UnitTest)

@property (nonatomic, strong) id<LPNetworkEngineProtocol> engine;

- (void)sendNow:(id<LPRequesting>)request sync:(BOOL)sync;
- (void)sendRequests:(BOOL)sync;
- (NSOperationQueue *)sendNowQueue;

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

- (void)testCreateArgsDictionaryForRequest {
    LPRequest *request = [LPRequest post:@"test" params:@{}];
    LPRequestSender *requestSender = [[LPRequestSender alloc] init];
    LPConstantsState *constants = [LPConstantsState sharedState];
    NSString *timestamp = [NSString stringWithFormat:@"%f", [[NSDate date] timeIntervalSince1970]];
    NSMutableDictionary *testArgs = [@{
                                   LP_PARAM_ACTION: @"test",
                                   LP_PARAM_DEVICE_ID: @"",
                                   LP_PARAM_USER_ID: @"",
                                   LP_PARAM_SDK_VERSION: constants.sdkVersion,
                                   LP_PARAM_CLIENT: constants.client,
                                   LP_PARAM_DEV_MODE: @(constants.isDevelopmentModeEnabled),
                                   LP_PARAM_TIME: timestamp,
                                   LP_PARAM_UUID: @"uuid",
                                   } mutableCopy];
    NSMutableDictionary *args = [requestSender createArgsDictionaryForRequest:request];
    args[LP_PARAM_UUID] = @"uuid";
    args[LP_PARAM_TIME] = timestamp;
    
    XCTAssertEqualObjects(testArgs, args);
}

- (void)testSendNow {
    LPRequest *request = [LPRequest post:@"test" params:@{}];
    LPRequestSender *requestSender = [[LPRequestSender alloc] init];
    id requestSenderMock = OCMPartialMock(requestSender);
    id configMock = OCMClassMock([LPAPIConfig class]);
    OCMStub([configMock sharedConfig]).andReturn(configMock);
    OCMStub([configMock appId]).andReturn(@"appID");
    OCMStub([configMock accessKey]).andReturn(@"accessKey");
    [requestSender sendNow:request];

    OCMVerify([requestSenderMock sendNow:request sync:false]);
    OCMVerify([requestSenderMock sendEventually:request]);
    OCMVerify([requestSenderMock sendRequests:false]);
    
    [requestSenderMock stopMocking];
    [configMock stopMocking];
}

- (void)testSendEventually {
    LPRequest *request = [LPRequest post:@"test" params:@{}];
    LPRequestSender *requestSender = [[LPRequestSender alloc] init];
    id eventDataManagerMock = OCMClassMock([LPEventDataManager class]);
    [requestSender sendEventually:request];

    OCMVerify([eventDataManagerMock addEvent:[OCMArg isNotNil]]);

    [eventDataManagerMock stopMocking];
}

- (void)testSendIfConnected {
    LPRequest *request = [LPRequest post:@"test" params:@{}];
    LPRequestSender *requestSender = [[LPRequestSender alloc] init];
    id requestSenderMock = OCMPartialMock(requestSender);
    id reachabilityMock = OCMClassMock([Leanplum_Reachability class]);
    OCMStub([reachabilityMock reachabilityForInternetConnection]).andReturn(reachabilityMock);
    OCMStub([reachabilityMock isReachable]).andReturn(true);
    [requestSender sendIfConnected:request];

    OCMVerify([requestSenderMock sendNow:request]);
    
    [requestSenderMock stopMocking];
}

- (void)testSendIfNotConnected {
    LPRequest *request = [LPRequest post:@"test" params:@{}];
    LPRequestSender *requestSender = [[LPRequestSender alloc] init];
    id requestSenderMock = OCMPartialMock(requestSender);
    id reachabilityMock = OCMClassMock([Leanplum_Reachability class]);
    OCMStub([reachabilityMock reachabilityForInternetConnection]).andReturn(reachabilityMock);
    OCMStub([reachabilityMock isReachable]).andReturn(false);
    [requestSender sendIfConnected:request];

    OCMVerify([requestSenderMock sendEventually:request]);
    
    [requestSenderMock stopMocking];
    [reachabilityMock stopMocking];
}

- (void)testSendNowWithData {
    LPRequest *request = [LPRequest post:@"test" params:@{}];
    LPRequestSender *requestSender = [[LPRequestSender alloc] init];
    id requestSenderMock = OCMPartialMock(requestSender);

    NSMutableDictionary *data = [[NSMutableDictionary alloc] init];
    data [@"key"] = [@"value" dataUsingEncoding:NSUTF8StringEncoding];
    [requestSender sendNow:request withData:data[@"key"] forKey:@"key"];

    OCMVerify([requestSenderMock sendNow:request withDatas:data]);
    
    [requestSenderMock stopMocking];
}

- (void)testSendNowWithDatas {
    LPRequest *request = [LPRequest post:@"test" params:@{}];
    LPRequestSender *requestSender = [[LPRequestSender alloc] init];
    requestSender.engine = OCMProtocolMock(@protocol(LPNetworkEngineProtocol));
    id opMock = OCMProtocolMock(@protocol(LPNetworkOperationProtocol));
    OCMStub([requestSender.engine operationWithPath:[OCMArg any] params:[OCMArg any] httpMethod:[OCMArg any] ssl:[OCMArg any] timeoutSeconds:60]).andReturn(opMock);

    NSMutableDictionary *datas = [[NSMutableDictionary alloc] init];
    datas[@"key"] = [@"value" dataUsingEncoding:NSUTF8StringEncoding];
    [requestSender sendNow:request withDatas:datas];

    OCMVerify([requestSender.engine enqueueOperation:opMock]);
    OCMVerify([opMock addData:datas[@"key"] forKey:@"key"]);
    OCMVerify([opMock addCompletionHandler:[OCMArg any] errorHandler:[OCMArg any]]);
}

- (void) testSendRequestsSync {
    LPRequestSender *requestSender = [[LPRequestSender alloc] init];
    id requestOperationMock = OCMClassMock([NSBlockOperation class]);
    OCMStub([NSBlockOperation new]).andReturn(requestOperationMock);
    id eventDataManagerMock = OCMClassMock([LPEventDataManager class]);

    NSMutableArray *requestsToSend = [[NSMutableArray alloc] init];
    [requestsToSend addObject:[[NSMutableDictionary alloc] init]];

    OCMStub([eventDataManagerMock eventsWithLimit:MAX_EVENTS_PER_API_CALL]).andReturn(requestsToSend);
    requestSender.engine = OCMProtocolMock(@protocol(LPNetworkEngineProtocol));

    LPConstantsState *constants = [LPConstantsState sharedState];
    int timeout = 5 * constants.syncNetworkTimeoutSeconds;

    id opMock = OCMProtocolMock(@protocol(LPNetworkOperationProtocol));
    OCMStub([requestSender.engine operationWithPath:[OCMArg any] params:[OCMArg any] httpMethod:[OCMArg any] ssl:[OCMArg any] timeoutSeconds:timeout]).andReturn(opMock);
    [requestSender sendRequests:true];

    OCMVerify([eventDataManagerMock eventsWithLimit:MAX_EVENTS_PER_API_CALL]);
    OCMVerify([requestSender.engine operationWithPath:[OCMArg any] params:[OCMArg any] httpMethod:[OCMArg any] ssl:[OCMArg any] timeoutSeconds:timeout]);
    OCMVerify([opMock addCompletionHandler:[OCMArg any] errorHandler:[OCMArg any]]);
    OCMVerify([requestSender.engine enqueueOperation:opMock]);

    [requestOperationMock stopMocking];
    [eventDataManagerMock stopMocking];
}

- (void) testSendRequestsAsync {
    LPRequestSender *requestSender = OCMPartialMock([[LPRequestSender alloc] init]);
    id requestOperationMock = OCMClassMock([NSBlockOperation class]);
    OCMStub([requestOperationMock new]).andReturn(requestOperationMock);
    id mockQueue = OCMClassMock([NSOperationQueue class]);
    OCMStub([requestSender sendNowQueue]).andReturn(mockQueue);
    [requestSender sendRequests:false];

    OCMVerify([requestOperationMock addExecutionBlock:[OCMArg any]]);
    OCMVerify([mockQueue addOperation:requestOperationMock]);
    
    [requestOperationMock stopMocking];
    [mockQueue stopMocking];
}
@end
