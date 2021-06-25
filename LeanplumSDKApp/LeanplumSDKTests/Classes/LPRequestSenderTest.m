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
#import "LeanplumHelper.h"
#import <Leanplum/LPOperationQueue.h>

@interface LPRequestSender(UnitTest)

@property (nonatomic, strong) id<LPNetworkEngineProtocol> engine;

- (void)sendNow:(LPRequest *)request;
- (void)sendRequests;
- (void)saveRequest:request;

@end

@interface LPRequestSenderTest : XCTestCase

@end

@implementation LPRequestSenderTest

+ (void)setUp
{
    [super setUp];
    // Called only once to setup method swizzling.
    [LeanplumHelper setup_method_swizzling];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testSend {
    LPRequest *request = [LPRequest post:@"test" params:@{}];
    LPRequestSender *requestSender = [[LPRequestSender alloc] init];
    id requestSenderMock = OCMPartialMock(requestSender);
    id configMock = OCMClassMock([LPAPIConfig class]);
    OCMStub([configMock sharedConfig]).andReturn(configMock);
    OCMStub([configMock appId]).andReturn(@"appID");
    OCMStub([configMock accessKey]).andReturn(@"accessKey");
    [requestSender send:request];

    [[[requestSenderMock verify] ignoringNonObjectArgs] saveRequest:request];

    [requestSenderMock stopMocking];
    [configMock stopMocking];
}

- (void)testSendImmediateRequest {
    LPRequest *request = [[LPRequest post:@"test" params:@{}] andRequestType:Immediate];
    LPRequestSender *requestSender = [[LPRequestSender alloc] init];
    id requestSenderMock = OCMPartialMock(requestSender);
    id configMock = OCMClassMock([LPAPIConfig class]);
    OCMStub([configMock sharedConfig]).andReturn(configMock);
    OCMStub([configMock appId]).andReturn(@"appID");
    OCMStub([configMock accessKey]).andReturn(@"accessKey");
    [requestSender send:request];

    [[[requestSenderMock verify] ignoringNonObjectArgs] sendNow:request];
    [[[requestSenderMock verify] ignoringNonObjectArgs] saveRequest:request];
    [[[requestSenderMock verify] ignoringNonObjectArgs] sendRequests];
    
    [requestSenderMock stopMocking];
    [configMock stopMocking];
}

- (void)testSaveRequest {
    LPRequest *request = [LPRequest post:@"test" params:@{}];
    LPRequestSender *requestSender = [[LPRequestSender alloc] init];
    id operationQueueMock = OCMClassMock([LPOperationQueue class]);
    id eventDataManagerMock = OCMClassMock([LPEventDataManager class]);
    [requestSender saveRequest:request];

    OCMVerify([[operationQueueMock serialQueue] addOperation:[OCMArg any]]);
    
    //wait one sec for operationQueue to execute the operation and check if addEvent is called
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        sleep(1);
        dispatch_semaphore_signal(semaphore);
    });
    long timedOut = dispatch_semaphore_wait(semaphore, [LeanplumHelper default_dispatch_time]);
    XCTAssertTrue(timedOut == 0);
    OCMVerify([eventDataManagerMock addEvent:[OCMArg any]]);

    [eventDataManagerMock stopMocking];
    [operationQueueMock stopMocking];
}

- (void)testSendIfConnected {
    LPRequest *request = [[LPRequest post:@"test" params:@{}] andRequestType:Immediate];
    LPRequestSender *requestSender = [[LPRequestSender alloc] init];
    id requestSenderMock = OCMPartialMock(requestSender);
    id reachabilityMock = OCMClassMock([Leanplum_Reachability class]);
    OCMStub([reachabilityMock reachabilityForInternetConnection]).andReturn(reachabilityMock);
    OCMStub([reachabilityMock isReachable]).andReturn(true);
    [requestSender send:request];

    OCMVerify([requestSenderMock sendRequests]);

    [requestSenderMock stopMocking];
}

- (void)testSendIfNotConnected {
    LPRequest *request = [[LPRequest post:@"test" params:@{}] andRequestType:Immediate];
    LPRequestSender *requestSender = [[LPRequestSender alloc] init];
    id requestSenderMock = OCMPartialMock(requestSender);
    id reachabilityMock = OCMClassMock([Leanplum_Reachability class]);
    OCMStub([reachabilityMock reachabilityForInternetConnection]).andReturn(reachabilityMock);
    OCMStub([reachabilityMock isReachable]).andReturn(false);
    [requestSender send:request];

    [[[requestSenderMock verify] ignoringNonObjectArgs] saveRequest:request];

    [requestSenderMock stopMocking];
    [reachabilityMock stopMocking];
}

- (void)testSendNowWithDatas {
    LPRequest *request = [[LPRequest post:@"test" params:@{}] andRequestType:Immediate];
    LPRequestSender *requestSender = [[LPRequestSender alloc] init];
    requestSender.engine = OCMProtocolMock(@protocol(LPNetworkEngineProtocol));
    id opMock = OCMProtocolMock(@protocol(LPNetworkOperationProtocol));
    OCMStub([requestSender.engine operationWithPath:[OCMArg any] params:[OCMArg any] httpMethod:[OCMArg any] ssl:[OCMArg any] timeoutSeconds:60]).andReturn(opMock);

    NSMutableDictionary *datas = [[NSMutableDictionary alloc] init];
    datas[@"key"] = [@"value" dataUsingEncoding:NSUTF8StringEncoding];
    request.datas = datas;
    [requestSender send:request];

    OCMVerify([requestSender.engine enqueueOperation:opMock]);
    OCMVerify([opMock addData:datas[@"key"] forKey:@"key"]);
    OCMVerify([opMock addCompletionHandler:[OCMArg any] errorHandler:[OCMArg any]]);
}

@end
