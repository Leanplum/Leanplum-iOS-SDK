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
#import <Leanplum/LeanplumRequest.h>
#import <Leanplum/LPRequest.h>

NSString *LP_API_METHOD_START = @"start";
NSString *LP_API_METHOD_GET_VARS = @"getVars";
NSString *LP_API_METHOD_SET_VARS = @"setVars";
NSString *LP_API_METHOD_STOP = @"stop";
NSString *LP_API_METHOD_RESTART = @"restart";
NSString *LP_API_METHOD_TRACK = @"track";
NSString *LP_API_METHOD_ADVANCE = @"advance";
NSString *LP_API_METHOD_PAUSE_SESSION = @"pauseSession";
NSString *LP_API_METHOD_PAUSE_STATE = @"pauseState";
NSString *LP_API_METHOD_RESUME_SESSION = @"resumeSession";
NSString *LP_API_METHOD_RESUME_STATE = @"resumeState";
NSString *LP_API_METHOD_MULTI = @"multi";
NSString *LP_API_METHOD_REGISTER_FOR_DEVELOPMENT = @"registerDevice";
NSString *LP_API_METHOD_SET_USER_ATTRIBUTES = @"setUserAttributes";
NSString *LP_API_METHOD_SET_DEVICE_ATTRIBUTES = @"setDeviceAttributes";
NSString *LP_API_METHOD_SET_TRAFFIC_SOURCE_INFO = @"setTrafficSourceInfo";
NSString *LP_API_METHOD_UPLOAD_FILE = @"uploadFile";
NSString *LP_API_METHOD_DOWNLOAD_FILE = @"downloadFile";
NSString *LP_API_METHOD_HEARTBEAT = @"heartbeat";
NSString *LP_API_METHOD_SAVE_VIEW_CONTROLLER_VERSION = @"saveInterface";
NSString *LP_API_METHOD_SAVE_VIEW_CONTROLLER_IMAGE = @"saveInterfaceImage";
NSString *LP_API_METHOD_GET_VIEW_CONTROLLER_VERSIONS_LIST = @"getViewControllerVersionsList";
NSString *LP_API_METHOD_LOG = @"log";
NSString *LP_API_METHOD_GET_INBOX_MESSAGES = @"getNewsfeedMessages";
NSString *LP_API_METHOD_MARK_INBOX_MESSAGE_AS_READ = @"markNewsfeedMessageAsRead";
NSString *LP_API_METHOD_DELETE_INBOX_MESSAGE = @"deleteNewsfeedMessage";

@interface LPRequestFactory(UnitTest)

@property (nonatomic, strong) LPFeatureFlagManager *featureFlagManager;

- (id<LPRequesting>)createGetForApiMethod:(NSString *)apiMethod params:(NSDictionary *)params;
- (id<LPRequesting>)createPostForApiMethod:(NSString *)apiMethod params:(NSDictionary *)params;
- (BOOL)shouldReturnLPRequestClass;

@end

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
    LPFeatureFlagManager *featureFlagManager = [[LPFeatureFlagManager alloc] init];
    LPRequestFactory *reqFactory = [[LPRequestFactory alloc]
                                    initWithFeatureFlagManager:featureFlagManager];
    id LPRequestMock = OCMClassMock([LPRequest class]);
    reqFactory.featureFlagManager = OCMClassMock([LPFeatureFlagManager class]);
    OCMStub([reqFactory.featureFlagManager isFeatureFlagEnabled:LP_FEATURE_FLAG_REQUEST_REFACTOR]).andReturn(true);
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    params[@"key"] = @"value";
    NSString *apiMethod = @"ApiMethod";
    
    [reqFactory createGetForApiMethod:apiMethod params:params];
    
    OCMVerify([LPRequestMock get:apiMethod params:params]);
}

- (void)testCreateGetForApiMethodLeanplumRequest {
    LPFeatureFlagManager *featureFlagManager = [[LPFeatureFlagManager alloc] init];
    LPRequestFactory *reqFactory = [[LPRequestFactory alloc]
                                    initWithFeatureFlagManager:featureFlagManager];
    id LeanplumRequestMock = OCMClassMock([LeanplumRequest class]);
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    params[@"key"] = @"value";
    NSString *apiMethod = @"ApiMethod";
    
    [reqFactory createGetForApiMethod:apiMethod params:params];
    
    OCMVerify([LeanplumRequestMock get:apiMethod params:params]);
}

- (void)testCreatePostForApiMethodLPRequest {
    LPFeatureFlagManager *featureFlagManager = [[LPFeatureFlagManager alloc] init];
    LPRequestFactory *reqFactory = [[LPRequestFactory alloc]
                                    initWithFeatureFlagManager:featureFlagManager];
    id LPRequestMock = OCMClassMock([LPRequest class]);
    reqFactory.featureFlagManager = OCMClassMock([LPFeatureFlagManager class]);
    OCMStub([reqFactory.featureFlagManager isFeatureFlagEnabled:LP_FEATURE_FLAG_REQUEST_REFACTOR]).andReturn(true);
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    params[@"key"] = @"value";
    NSString *apiMethod = @"ApiMethod";
    
    [reqFactory createPostForApiMethod:apiMethod params:params];
    
    OCMVerify([LPRequestMock post:apiMethod params:params]);
}

- (void)testCreatePostForApiMethodLeanplumRequest {
    LPFeatureFlagManager *featureFlagManager = [[LPFeatureFlagManager alloc] init];
    LPRequestFactory *reqFactory = [[LPRequestFactory alloc]
                                    initWithFeatureFlagManager:featureFlagManager];
    id LeanplumRequestMock = OCMClassMock([LeanplumRequest class]);
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    params[@"key"] = @"value";
    NSString *apiMethod = @"ApiMethod";
    
    [reqFactory createPostForApiMethod:apiMethod params:params];
    
    OCMVerify([LeanplumRequestMock post:apiMethod params:params]);
}

- (void)testStartWithParams {
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    params[@"key"] = @"value";
    LPFeatureFlagManager *featureFlagManager = [[LPFeatureFlagManager alloc] init];
    LPRequestFactory *reqFactory = [[LPRequestFactory alloc]
                                    initWithFeatureFlagManager:featureFlagManager];
    id reqFactoryMock = OCMPartialMock(reqFactory);
    [reqFactory startWithParams:params];
 
    OCMVerify([reqFactoryMock createPostForApiMethod:LP_API_METHOD_START params:params]);
}

- (void)testGetVarsWithParams {
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    params[@"key"] = @"value";
    LPFeatureFlagManager *featureFlagManager = [[LPFeatureFlagManager alloc] init];
    LPRequestFactory *reqFactory = [[LPRequestFactory alloc]
                                    initWithFeatureFlagManager:featureFlagManager];
    id reqFactoryMock = OCMPartialMock(reqFactory);
    [reqFactory getVarsWithParams:params];
    
    OCMVerify([reqFactoryMock createPostForApiMethod:LP_API_METHOD_GET_VARS params:params]);
}

- (void)testSetVarsWithParams {
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    params[@"key"] = @"value";
    LPFeatureFlagManager *featureFlagManager = [[LPFeatureFlagManager alloc] init];
    LPRequestFactory *reqFactory = [[LPRequestFactory alloc]
                                    initWithFeatureFlagManager:featureFlagManager];
    id reqFactoryMock = OCMPartialMock(reqFactory);
    [reqFactory setVarsWithParams:params];
    
    OCMVerify([reqFactoryMock createPostForApiMethod:LP_API_METHOD_SET_VARS params:params]);
}

- (void)testStopWithParams {
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    params[@"key"] = @"value";
    LPFeatureFlagManager *featureFlagManager = [[LPFeatureFlagManager alloc] init];
    LPRequestFactory *reqFactory = [[LPRequestFactory alloc]
                                    initWithFeatureFlagManager:featureFlagManager];
    id reqFactoryMock = OCMPartialMock(reqFactory);
    [reqFactory stopWithParams:params];
    
    OCMVerify([reqFactoryMock createPostForApiMethod:LP_API_METHOD_STOP params:params]);
}

- (void)testRestartWithParams {
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    params[@"key"] = @"value";
    LPFeatureFlagManager *featureFlagManager = [[LPFeatureFlagManager alloc] init];
    LPRequestFactory *reqFactory = [[LPRequestFactory alloc]
                                    initWithFeatureFlagManager:featureFlagManager];
    id reqFactoryMock = OCMPartialMock(reqFactory);
    [reqFactory restartWithParams:params];
    
    OCMVerify([reqFactoryMock createPostForApiMethod:LP_API_METHOD_RESTART params:params]);
}

- (void)testTrackWithParams {
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    params[@"key"] = @"value";
    LPFeatureFlagManager *featureFlagManager = [[LPFeatureFlagManager alloc] init];
    LPRequestFactory *reqFactory = [[LPRequestFactory alloc]
                                    initWithFeatureFlagManager:featureFlagManager];
    id reqFactoryMock = OCMPartialMock(reqFactory);
    [reqFactory trackWithParams:params];
    
    OCMVerify([reqFactoryMock createPostForApiMethod:LP_API_METHOD_TRACK params:params]);
}

- (void)testAdvanceWithParams {
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    params[@"key"] = @"value";
    LPFeatureFlagManager *featureFlagManager = [[LPFeatureFlagManager alloc] init];
    LPRequestFactory *reqFactory = [[LPRequestFactory alloc]
                                    initWithFeatureFlagManager:featureFlagManager];
    id reqFactoryMock = OCMPartialMock(reqFactory);
    [reqFactory advanceWithParams:params];
    
    OCMVerify([reqFactoryMock createPostForApiMethod:LP_API_METHOD_ADVANCE params:params]);
}

- (void)testPauseSessionWithParams {
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    params[@"key"] = @"value";
    LPFeatureFlagManager *featureFlagManager = [[LPFeatureFlagManager alloc] init];
    LPRequestFactory *reqFactory = [[LPRequestFactory alloc]
                                    initWithFeatureFlagManager:featureFlagManager];
    id reqFactoryMock = OCMPartialMock(reqFactory);
    [reqFactory pauseSessionWithParams:params];
    
    OCMVerify([reqFactoryMock createPostForApiMethod:LP_API_METHOD_PAUSE_SESSION params:params]);
}

- (void)testPauseStateWithParams {
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    params[@"key"] = @"value";
    LPFeatureFlagManager *featureFlagManager = [[LPFeatureFlagManager alloc] init];
    LPRequestFactory *reqFactory = [[LPRequestFactory alloc]
                                    initWithFeatureFlagManager:featureFlagManager];
    id reqFactoryMock = OCMPartialMock(reqFactory);
    [reqFactory pauseStateWithParams:params];
    
    OCMVerify([reqFactoryMock createPostForApiMethod:LP_API_METHOD_PAUSE_STATE params:params]);
}

- (void)testResumeSessionWithParams {
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    params[@"key"] = @"value";
    LPFeatureFlagManager *featureFlagManager = [[LPFeatureFlagManager alloc] init];
    LPRequestFactory *reqFactory = [[LPRequestFactory alloc]
                                    initWithFeatureFlagManager:featureFlagManager];
    id reqFactoryMock = OCMPartialMock(reqFactory);
    [reqFactory resumeSessionWithParams:params];
    
    OCMVerify([reqFactoryMock createPostForApiMethod:LP_API_METHOD_RESUME_SESSION params:params]);
}

- (void)testResumeStateWithParams {
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    params[@"key"] = @"value";
    LPFeatureFlagManager *featureFlagManager = [[LPFeatureFlagManager alloc] init];
    LPRequestFactory *reqFactory = [[LPRequestFactory alloc]
                                    initWithFeatureFlagManager:featureFlagManager];
    id reqFactoryMock = OCMPartialMock(reqFactory);
    [reqFactory resumeStateWithParams:params];
    
    OCMVerify([reqFactoryMock createPostForApiMethod:LP_API_METHOD_RESUME_STATE params:params]);
}

- (void)testMultiWithParams {
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    params[@"key"] = @"value";
    LPFeatureFlagManager *featureFlagManager = [[LPFeatureFlagManager alloc] init];
    LPRequestFactory *reqFactory = [[LPRequestFactory alloc]
                                    initWithFeatureFlagManager:featureFlagManager];
    id reqFactoryMock = OCMPartialMock(reqFactory);
    [reqFactory multiWithParams:params];
    
    OCMVerify([reqFactoryMock createPostForApiMethod:LP_API_METHOD_MULTI params:params]);
}

- (void)testRegisterDeviceWithParams {
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    params[@"key"] = @"value";
    LPFeatureFlagManager *featureFlagManager = [[LPFeatureFlagManager alloc] init];
    LPRequestFactory *reqFactory = [[LPRequestFactory alloc]
                                    initWithFeatureFlagManager:featureFlagManager];
    id reqFactoryMock = OCMPartialMock(reqFactory);
    [reqFactory registerDeviceWithParams:params];
    
    OCMVerify([reqFactoryMock createPostForApiMethod:LP_API_METHOD_REGISTER_FOR_DEVELOPMENT params:params]);
}

- (void)testSetUserAttributesWithParams {
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    params[@"key"] = @"value";
    LPFeatureFlagManager *featureFlagManager = [[LPFeatureFlagManager alloc] init];
    LPRequestFactory *reqFactory = [[LPRequestFactory alloc]
                                    initWithFeatureFlagManager:featureFlagManager];
    id reqFactoryMock = OCMPartialMock(reqFactory);
    [reqFactory setUserAttributesWithParams:params];
    
    OCMVerify([reqFactoryMock createPostForApiMethod:LP_API_METHOD_SET_USER_ATTRIBUTES params:params]);
}

- (void)testSetDeviceAttributesWithParams {
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    params[@"key"] = @"value";
    LPFeatureFlagManager *featureFlagManager = [[LPFeatureFlagManager alloc] init];
    LPRequestFactory *reqFactory = [[LPRequestFactory alloc]
                                    initWithFeatureFlagManager:featureFlagManager];
    id reqFactoryMock = OCMPartialMock(reqFactory);
    [reqFactory setDeviceAttributesWithParams:params];
    
    OCMVerify([reqFactoryMock createPostForApiMethod:LP_API_METHOD_SET_DEVICE_ATTRIBUTES params:params]);
}

- (void)testSetTrafficSourceInfoWithParams {
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    params[@"key"] = @"value";
    LPFeatureFlagManager *featureFlagManager = [[LPFeatureFlagManager alloc] init];
    LPRequestFactory *reqFactory = [[LPRequestFactory alloc]
                                    initWithFeatureFlagManager:featureFlagManager];
    id reqFactoryMock = OCMPartialMock(reqFactory);
    [reqFactory setTrafficSourceInfoWithParams:params];
    
    OCMVerify([reqFactoryMock createPostForApiMethod:LP_API_METHOD_SET_TRAFFIC_SOURCE_INFO params:params]);
}

- (void)testUploadFileWithParams {
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    params[@"key"] = @"value";
    LPFeatureFlagManager *featureFlagManager = [[LPFeatureFlagManager alloc] init];
    LPRequestFactory *reqFactory = [[LPRequestFactory alloc]
                                    initWithFeatureFlagManager:featureFlagManager];
    id reqFactoryMock = OCMPartialMock(reqFactory);
    [reqFactory uploadFileWithParams:params];
    
    OCMVerify([reqFactoryMock createPostForApiMethod:LP_API_METHOD_UPLOAD_FILE params:params]);
}

- (void)testDownloadFileWithParams {
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    params[@"key"] = @"value";
    LPFeatureFlagManager *featureFlagManager = [[LPFeatureFlagManager alloc] init];
    LPRequestFactory *reqFactory = [[LPRequestFactory alloc]
                                    initWithFeatureFlagManager:featureFlagManager];
    id reqFactoryMock = OCMPartialMock(reqFactory);
    [reqFactory downloadFileWithParams:params];
    
    OCMVerify([reqFactoryMock createGetForApiMethod:LP_API_METHOD_DOWNLOAD_FILE params:params]);
}

- (void)testHeartbeatWithParams {
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    params[@"key"] = @"value";
    LPFeatureFlagManager *featureFlagManager = [[LPFeatureFlagManager alloc] init];
    LPRequestFactory *reqFactory = [[LPRequestFactory alloc]
                                    initWithFeatureFlagManager:featureFlagManager];
    id reqFactoryMock = OCMPartialMock(reqFactory);
    [reqFactory heartbeatWithParams:params];
    
    OCMVerify([reqFactoryMock createPostForApiMethod:LP_API_METHOD_HEARTBEAT params:params]);
}

- (void)testSaveInterfaceWithParams {
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    params[@"key"] = @"value";
    LPFeatureFlagManager *featureFlagManager = [[LPFeatureFlagManager alloc] init];
    LPRequestFactory *reqFactory = [[LPRequestFactory alloc]
                                    initWithFeatureFlagManager:featureFlagManager];
    id reqFactoryMock = OCMPartialMock(reqFactory);
    [reqFactory saveInterfaceWithParams:params];
    
    OCMVerify([reqFactoryMock createPostForApiMethod:LP_API_METHOD_SAVE_VIEW_CONTROLLER_VERSION params:params]);
}

- (void)testSaveInterfaceImageWithParams {
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    params[@"key"] = @"value";
    LPFeatureFlagManager *featureFlagManager = [[LPFeatureFlagManager alloc] init];
    LPRequestFactory *reqFactory = [[LPRequestFactory alloc]
                                    initWithFeatureFlagManager:featureFlagManager];
    id reqFactoryMock = OCMPartialMock(reqFactory);
    [reqFactory saveInterfaceImageWithParams:params];
    
    OCMVerify([reqFactoryMock createPostForApiMethod:LP_API_METHOD_SAVE_VIEW_CONTROLLER_IMAGE params:params]);
}

- (void)testGetViewControllerVersionsListWithParams {
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    params[@"key"] = @"value";
    LPFeatureFlagManager *featureFlagManager = [[LPFeatureFlagManager alloc] init];
    LPRequestFactory *reqFactory = [[LPRequestFactory alloc]
                                    initWithFeatureFlagManager:featureFlagManager];
    id reqFactoryMock = OCMPartialMock(reqFactory);
    [reqFactory getViewControllerVersionsListWithParams:params];
    
    OCMVerify([reqFactoryMock createPostForApiMethod:LP_API_METHOD_GET_VIEW_CONTROLLER_VERSIONS_LIST params:params]);
}

- (void)testLogWithParams {
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    params[@"key"] = @"value";
    LPFeatureFlagManager *featureFlagManager = [[LPFeatureFlagManager alloc] init];
    LPRequestFactory *reqFactory = [[LPRequestFactory alloc]
                                    initWithFeatureFlagManager:featureFlagManager];
    id reqFactoryMock = OCMPartialMock(reqFactory);
    [reqFactory logWithParams:params];
    
    OCMVerify([reqFactoryMock createPostForApiMethod:LP_API_METHOD_LOG params:params]);
}

- (void)testGetNewsfeedMessagesWithParams {
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    params[@"key"] = @"value";
    LPFeatureFlagManager *featureFlagManager = [[LPFeatureFlagManager alloc] init];
    LPRequestFactory *reqFactory = [[LPRequestFactory alloc]
                                    initWithFeatureFlagManager:featureFlagManager];
    id reqFactoryMock = OCMPartialMock(reqFactory);
    [reqFactory getNewsfeedMessagesWithParams:params];
    
    OCMVerify([reqFactoryMock createPostForApiMethod:LP_API_METHOD_GET_INBOX_MESSAGES params:params]);
}

- (void)testMarkNewsfeedMessageAsReadWithParams {
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    params[@"key"] = @"value";
    LPFeatureFlagManager *featureFlagManager = [[LPFeatureFlagManager alloc] init];
    LPRequestFactory *reqFactory = [[LPRequestFactory alloc]
                                    initWithFeatureFlagManager:featureFlagManager];
    id reqFactoryMock = OCMPartialMock(reqFactory);
    [reqFactory markNewsfeedMessageAsReadWithParams:params];
    
    OCMVerify([reqFactoryMock createPostForApiMethod:LP_API_METHOD_MARK_INBOX_MESSAGE_AS_READ params:params]);
}

- (void)testDeleteNewsfeedMessageWithParams {
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    params[@"key"] = @"value";
    LPFeatureFlagManager *featureFlagManager = [[LPFeatureFlagManager alloc] init];
    LPRequestFactory *reqFactory = [[LPRequestFactory alloc]
                                    initWithFeatureFlagManager:featureFlagManager];
    id reqFactoryMock = OCMPartialMock(reqFactory);
    [reqFactory deleteNewsfeedMessageWithParams:params];
    
    OCMVerify([reqFactoryMock createPostForApiMethod:LP_API_METHOD_DELETE_INBOX_MESSAGE params:params]);
}

@end

