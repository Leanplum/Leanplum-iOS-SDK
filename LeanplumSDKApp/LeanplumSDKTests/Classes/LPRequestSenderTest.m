//
//  LPRequestSenderTest.m
//  Leanplum-SDK_Tests
//
//  Created by Grace Gu on 10/01/18.
//  Copyright © 2018 Leanplum. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import <OHHTTPStubs/HTTPStubs.h>
#import <OHHTTPStubs/HTTPStubsPathHelpers.h>
#import <OHHTTPStubs/HTTPStubsResponse+JSON.h>
#import <Leanplum/LPEventDataManager.h>
#import <Leanplum/LPNetworkProtocol.h>
#import <Leanplum/LPRequestSender.h>
#import <Leanplum/LPRequestFactory.h>
#import <Leanplum/LPRequest.h>
#import <Leanplum/LPCountAggregator.h>
#import "LeanplumHelper.h"
#import <Leanplum/LPOperationQueue.h>
#import <Leanplum/Leanplum-Swift.h>

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

}

- (void)setUp {
    [LeanplumHelper setup_development_test];
    [[LPConstantsState sharedState] setIsDevelopmentModeEnabled:YES];
    [Leanplum setAppId:@"test" withDevelopmentKey:@"test"];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [LeanplumHelper clean_up];
    [Leanplum setApiHostName:API_HOST withPath:API_PATH usingSsl:YES];
    [Leanplum setSocketHostName:@"dev.leanplum.com" withPortNumber:443];
    [HTTPStubs removeAllStubs];
}

- (void)testSend {
    LPRequest *request = [LPRequest post:@"test" params:@{}];
    LPRequestSender *requestSender = [[LPRequestSender alloc] init];
    id requestSenderMock = OCMPartialMock(requestSender);
    id configMock = OCMClassMock([ApiConfig class]);
    OCMStub([configMock shared]).andReturn(configMock);
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
    id configMock = OCMClassMock([ApiConfig class]);
    OCMStub([configMock shared]).andReturn(configMock);
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
    [[LPConstantsState sharedState] setIsDevelopmentModeEnabled:YES];
    LPRequest *request = [[LPRequest post:@"test" params:@{}] andRequestType:Immediate];
    LPRequestSender *requestSender = [[LPRequestSender alloc] init];
    id requestSenderMock = OCMPartialMock(requestSender);
    id reachabilityMock = OCMClassMock([Leanplum_Reachability class]);
    OCMStub([reachabilityMock reachabilityForInternetConnection]).andReturn(reachabilityMock);
    OCMStub([reachabilityMock isReachable]).andReturn(true);
    [requestSender send:request];

    OCMVerify([requestSenderMock sendRequests]);

    [requestSenderMock stopMocking];
    [reachabilityMock stopMocking];
    [[LPConstantsState sharedState] setIsDevelopmentModeEnabled:NO];
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
    
    [opMock stopMocking];
}

- (void)testSendRequestsUpdateHost {
    [HTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest * _Nonnull request) {
        return [request.URL.host isEqualToString:API_HOST];
    } withStubResponse:^HTTPStubsResponse * _Nonnull(NSURLRequest * _Nonnull request) {
        NSString *response_file = OHPathForFile(@"change_host_response.json", self.class);
        return [HTTPStubsResponse responseWithFileAtPath:response_file statusCode:200
                                                   headers:@{@"Content-Type":@"application/json"}];
    }];
    
    XCTestExpectation *expectRetryOnNewHost = [self expectationWithDescription:@"request_update_host_expectation"];
    
    [HTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest * _Nonnull request) {
        return [request.URL.host isEqualToString:@"api2.leanplum.com"];
    } withStubResponse:^HTTPStubsResponse * _Nonnull(NSURLRequest * _Nonnull request) {
        [expectRetryOnNewHost fulfill];
        NSString *response_file = OHPathForFile(@"action_response.json", self.class);
        return [HTTPStubsResponse responseWithFileAtPath:response_file statusCode:200
                                                 headers:@{@"Content-Type":@"application/json"}];
    }];
    
    LPRequest *request = [[LPRequest post:@"testChangeHost" params:@{}] andRequestType:Immediate];
    // Use shared instance
    [[LPRequestSender sharedInstance] send:request];

    [self waitForExpectations:@[expectRetryOnNewHost] timeout:10];
}

- (void)testUpdateSocketHost {
    [HTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest * _Nonnull request) {
        return [request.URL.absoluteString hasPrefix:@"https://dev.leanplum.com:443/socket.io/1/?t="];
    } withStubResponse:^HTTPStubsResponse * _Nonnull(NSURLRequest * _Nonnull request) {
        NSString *success = @"abcD12Efj3d64oMN18cX-:60:60:websocket,xhr-polling,jsonp-polling";
        NSData *data = [success dataUsingEncoding:NSUTF8StringEncoding];
        return [HTTPStubsResponse responseWithData:data statusCode:200 headers:@{@"Content-Type":@"text/plain"}];
    }];
    
    [HTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest * _Nonnull request) {
        return [request.URL.absoluteString hasPrefix:@"https://api.leanplum.com"];
    } withStubResponse:^HTTPStubsResponse * _Nonnull(NSURLRequest * _Nonnull request) {
        NSString *response_file = OHPathForFile(@"change_host_response.json", self.class);
        return [HTTPStubsResponse responseWithFileAtPath:response_file statusCode:200
                                                   headers:@{@"Content-Type":@"application/json"}];
    }];
    
    XCTestExpectation *expectRetryOnNewHost = [self expectationWithDescription:@"request_update_socket_host_expectation"];    
    
    [HTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest * _Nonnull request) {
        return [request.URL.absoluteString hasPrefix:@"https://dev2.leanplum.com:443/socket.io/1/?t="];
    } withStubResponse:^HTTPStubsResponse * _Nonnull(NSURLRequest * _Nonnull request) {
        [expectRetryOnNewHost fulfill];
        NSString *successHandshake = @"zxcO67HekOa88oKI0cX-:60:60:websocket,xhr-polling,jsonp-polling";
        NSData *data = [successHandshake dataUsingEncoding:NSUTF8StringEncoding];
        return [HTTPStubsResponse responseWithData:data statusCode:200 headers:@{@"Content-Type":@"text/plain"}];
    }];
    
    // Connect to socket
    [[LeanplumSocket sharedSocket] connectToAppId:@"test" deviceId:@"test"];

    // Trigger host change through request sender
    LPRequest *request = [[LPRequest post:@"testChangeHost" params:@{}] andRequestType:Immediate];
    // Use shared instance
    [[LPRequestSender sharedInstance] send:request];

    [self waitForExpectations:@[expectRetryOnNewHost] timeout:10];
}

@end
