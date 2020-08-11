//
//  LPRequestFactoryTest.m
//  Leanplum-SDK_Tests
//
//  Created by Grace on 10/8/18.
//  Copyright © 2018 Leanplum. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import <Leanplum/LPRequestFactory.h>
#import <Leanplum/LPRequest.h>
#import <Leanplum/LPNetworkConstants.h>
#import "Leanplum+Extensions.h"

@interface LPRequestFactoryTest : XCTestCase

@end

@implementation LPRequestFactoryTest

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testCreateGetForApiMethodLPRequest {
    id LPRequestMock = OCMClassMock([LPRequest class]);
    NSString *apiMethod = @"test";
    
    [LPRequestFactory createGetForApiMethod:apiMethod params:nil];
    
    OCMVerify([LPRequestMock get:apiMethod params:nil]);
}

- (void)testCreatePostForApiMethodLPRequest {
    id LPRequestMock = OCMClassMock([LPRequest class]);
    NSString *apiMethod = @"ApiMethod";
    
    [LPRequestFactory createPostForApiMethod:apiMethod params:nil];
    
    OCMVerify([LPRequestMock post:apiMethod params:nil]);
}

- (void)testStartWithParams {
    [LPRequestFactory startWithParams:nil];
 
    OCMVerify([LPRequestFactory createPostForApiMethod:LP_API_METHOD_START params:nil]);
}

- (void)testGetVarsWithParams {
    [LPRequestFactory getVarsWithParams:nil];
    
    OCMVerify([LPRequestFactory createPostForApiMethod:LP_API_METHOD_GET_VARS params:nil]);
}

- (void)testSetVarsWithParams {
    [LPRequestFactory setVarsWithParams:nil];
    
    OCMVerify([LPRequestFactory createPostForApiMethod:LP_API_METHOD_SET_VARS params:nil]);
}

- (void)testStopWithParams {
    [LPRequestFactory stopWithParams:nil];
    
    OCMVerify([LPRequestFactory createPostForApiMethod:LP_API_METHOD_STOP params:nil]);
}

- (void)testRestartWithParams {
    [LPRequestFactory restartWithParams:nil];
    
    OCMVerify([LPRequestFactory createPostForApiMethod:LP_API_METHOD_RESTART params:nil]);
}

- (void)testTrackWithParams {
    [LPRequestFactory trackWithParams:nil];
    
    OCMVerify([LPRequestFactory createPostForApiMethod:LP_API_METHOD_TRACK params:nil]);
}

- (void)testAdvanceWithParams {
    [LPRequestFactory advanceWithParams:nil];
    
    OCMVerify([LPRequestFactory createPostForApiMethod:LP_API_METHOD_ADVANCE params:nil]);
}

- (void)testPauseSessionWithParams {
    [LPRequestFactory pauseSessionWithParams:nil];
    
    OCMVerify([LPRequestFactory createPostForApiMethod:LP_API_METHOD_PAUSE_SESSION params:nil]);
}

- (void)testPauseStateWithParams {
    [LPRequestFactory pauseStateWithParams:nil];
    
    OCMVerify([LPRequestFactory createPostForApiMethod:LP_API_METHOD_PAUSE_STATE params:nil]);
}

- (void)testResumeSessionWithParams {
    [LPRequestFactory resumeSessionWithParams:nil];
    
    OCMVerify([LPRequestFactory createPostForApiMethod:LP_API_METHOD_RESUME_SESSION params:nil]);
}

- (void)testResumeStateWithParams {
    [LPRequestFactory resumeStateWithParams:nil];
    
    OCMVerify([LPRequestFactory createPostForApiMethod:LP_API_METHOD_RESUME_STATE params:nil]);
}

- (void)testMultiWithParams {
    [LPRequestFactory multiWithParams:nil];
    
    OCMVerify([LPRequestFactory createPostForApiMethod:LP_API_METHOD_MULTI params:nil]);
}

- (void)testRegisterDeviceWithParams {
    [LPRequestFactory registerDeviceWithParams:nil];
    
    OCMVerify([LPRequestFactory createPostForApiMethod:LP_API_METHOD_REGISTER_FOR_DEVELOPMENT params:nil]);
}

- (void)testSetUserAttributesWithParams {
    [LPRequestFactory setUserAttributesWithParams:nil];
    
    OCMVerify([LPRequestFactory createPostForApiMethod:LP_API_METHOD_SET_USER_ATTRIBUTES params:nil]);
}

- (void)testSetDeviceAttributesWithParams {
    [LPRequestFactory setDeviceAttributesWithParams:nil];
    
    OCMVerify([LPRequestFactory createPostForApiMethod:LP_API_METHOD_SET_DEVICE_ATTRIBUTES params:nil]);
}

- (void)testSetTrafficSourceInfoWithParams {
    [LPRequestFactory setTrafficSourceInfoWithParams:nil];
    
    OCMVerify([LPRequestFactory createPostForApiMethod:LP_API_METHOD_SET_TRAFFIC_SOURCE_INFO params:nil]);
}

- (void)testUploadFileWithParams {
    [LPRequestFactory uploadFileWithParams:nil];
    
    OCMVerify([LPRequestFactory createPostForApiMethod:LP_API_METHOD_UPLOAD_FILE params:nil]);
}

- (void)testDownloadFileWithParams {
    [LPRequestFactory downloadFileWithParams:nil];
    
    OCMVerify([LPRequestFactory createGetForApiMethod:LP_API_METHOD_DOWNLOAD_FILE params:nil]);
}

- (void)testHeartbeatWithParams {
    [LPRequestFactory heartbeatWithParams:nil];
    
    OCMVerify([LPRequestFactory createPostForApiMethod:LP_API_METHOD_HEARTBEAT params:nil]);
}

- (void)testSaveInterfaceWithParams {
    [LPRequestFactory saveInterfaceWithParams:nil];
    
    OCMVerify([LPRequestFactory createPostForApiMethod:LP_API_METHOD_SAVE_VIEW_CONTROLLER_VERSION params:nil]);
}

- (void)testSaveInterfaceImageWithParams {
    [LPRequestFactory saveInterfaceImageWithParams:nil];
    
    OCMVerify([LPRequestFactory createPostForApiMethod:LP_API_METHOD_SAVE_VIEW_CONTROLLER_IMAGE params:nil]);
}

- (void)testGetViewControllerVersionsListWithParams {
    [LPRequestFactory getViewControllerVersionsListWithParams:nil];
    
    OCMVerify([LPRequestFactory createPostForApiMethod:LP_API_METHOD_GET_VIEW_CONTROLLER_VERSIONS_LIST params:nil]);
}

- (void)testLogWithParams {
    [LPRequestFactory logWithParams:nil];
    
    OCMVerify([LPRequestFactory createPostForApiMethod:LP_API_METHOD_LOG params:nil]);
}

- (void)testGetNewsfeedMessagesWithParams {
    [LPRequestFactory getNewsfeedMessagesWithParams:nil];
    
    OCMVerify([LPRequestFactory createPostForApiMethod:LP_API_METHOD_GET_INBOX_MESSAGES params:nil]);
}

- (void)testMarkNewsfeedMessageAsReadWithParams {
    [LPRequestFactory markNewsfeedMessageAsReadWithParams:nil];
    
    OCMVerify([LPRequestFactory createPostForApiMethod:LP_API_METHOD_MARK_INBOX_MESSAGE_AS_READ params:nil]);
}

- (void)testDeleteNewsfeedMessageWithParams {
    [LPRequestFactory deleteNewsfeedMessageWithParams:nil];
    
    OCMVerify([LPRequestFactory createPostForApiMethod:LP_API_METHOD_DELETE_INBOX_MESSAGE params:nil]);
}

@end

