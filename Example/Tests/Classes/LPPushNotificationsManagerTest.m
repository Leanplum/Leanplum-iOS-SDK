//
//  LPPushNotificationsManagerTest.m
//  Leanplum-SDK_Tests
//
//  Created by Dejan Krstevski on 19.05.20.
//  Copyright © 2020 Leanplum. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import <OHHTTPStubs/HTTPStubs.h>
#import <OHHTTPStubs/HTTPStubsPathHelpers.h>
#import "LeanplumHelper.h"
#import "LeanplumRequest+Categories.h"
#import "LPNetworkEngine+Category.h"
#import "Leanplum+Extensions.h"
#import "LPUIAlert.h"
#import "LPOperationQueue.h"
#import "LPPushNotificationsManager.h"
#import "LPNotificationsManager.h"

@interface LPPushNotificationsManager (Test)
- (void)leanplum_application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken;
@end

@interface LPPushNotificationsManagerTest : XCTestCase

@end

@implementation LPPushNotificationsManagerTest

+ (void)setUp
{
    [super setUp];
    // Called only once to setup method swizzling.
    [LeanplumHelper setup_method_swizzling];
}

- (void)setUp
{
    [super setUp];
    // Automatically sets up AppId and AccessKey for development mode.
    //[LeanplumHelper setup_development_test];
}

+ (void)tearDown
{
    [super tearDown];
    [LeanplumHelper clean_up];
}

- (void)tearDown
{
    [super tearDown];
    //[LeanplumHelper clean_up];
}

- (void)test_push_token
{
    XCTAssertTrue([LeanplumHelper start_production_test]);

    // Partial mock Action Manager.
    LPPushNotificationsManager *manager = [LPPushNotificationsManager sharedManager];
    id pushNotificationsManagerMock = OCMPartialMock(manager);
    OCMStub([LPPushNotificationsManager sharedManager]).andReturn(pushNotificationsManagerMock);
    OCMStub([pushNotificationsManagerMock respondsToSelector:
             @selector(leanplum_application:didRegisterForRemoteNotificationsWithDeviceToken:)]).andReturn(NO);

    // Remove Push Token.
    [manager removePushToken];

    // Test push token is sent on clean start.
    UIApplication *app = [UIApplication sharedApplication];
    XCTestExpectation *expectNewToken = [self expectationWithDescription:@"expectNewToken"];
    NSData *token = [@"sample" dataUsingEncoding:NSUTF8StringEncoding];
    NSString *formattedToken = [[LPNotificationsManager shared] hexadecimalStringFromData:token];
    formattedToken = [[[formattedToken stringByReplacingOccurrencesOfString:@"<" withString:@""]
                       stringByReplacingOccurrencesOfString:@">" withString:@""]
                      stringByReplacingOccurrencesOfString:@" " withString:@""];
    [LeanplumRequest validate_request:^BOOL(NSString *method, NSString *apiMethod,
                                            NSDictionary *params) {
        XCTAssertTrue([apiMethod isEqual:@"setDeviceAttributes"]);
        XCTAssertTrue([params[@"iosPushToken"] isEqual:formattedToken]);
        [expectNewToken fulfill];
        return YES;
    }];
    [manager leanplum_application:app didRegisterForRemoteNotificationsWithDeviceToken:token];
    [self waitForExpectationsWithTimeout:2 handler:nil];

    // Test push token will not be sent with the same token.
    [LeanplumRequest validate_request:^BOOL(NSString *method, NSString *apiMethod,
                                            NSDictionary *params) {
        XCTAssertTrue(NO);
        return YES;
    }];
    [manager leanplum_application:app didRegisterForRemoteNotificationsWithDeviceToken:token];

    // Test push token is sent if the token changes.
    token = [@"sample2" dataUsingEncoding:NSUTF8StringEncoding];
    formattedToken = [[LPNotificationsManager shared] hexadecimalStringFromData:token];
    formattedToken = [[[formattedToken stringByReplacingOccurrencesOfString:@"<" withString:@""]
                       stringByReplacingOccurrencesOfString:@">" withString:@""]
                      stringByReplacingOccurrencesOfString:@" " withString:@""];
    XCTestExpectation *expectUpdatedToken = [self expectationWithDescription:@"expectUpdatedToken"];
    [LeanplumRequest validate_request:^BOOL(NSString *method, NSString *apiMethod,
                                            NSDictionary *params) {
        XCTAssertTrue([apiMethod isEqual:@"setDeviceAttributes"]);
        XCTAssertTrue([params[LP_PARAM_DEVICE_PUSH_TOKEN] isEqual:formattedToken]);
        [expectUpdatedToken fulfill];
        return YES;
    }];
    [manager leanplum_application:app didRegisterForRemoteNotificationsWithDeviceToken:token];
    [[LPOperationQueue serialQueue] waitUntilAllOperationsAreFinished];
    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)removePushTypes
{
    NSString *settingsKey = [[LPPushNotificationsManager sharedManager] leanplum_createUserNotificationSettingsKey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:settingsKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)mockUserNotificationSettings
{
    id mockApplication = OCMClassMock([UIApplication class]);
    OCMStub([mockApplication sharedApplication]).andReturn(mockApplication);
    UIMutableUserNotificationCategory *cat = [[UIMutableUserNotificationCategory alloc] init];
    cat.identifier = @"testCategory";
    UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert categories:[NSSet setWithObject:cat]];
    OCMStub([mockApplication currentUserNotificationSettings]).andReturn(settings);
}

/**
 * Test iOS Push Types are sent when notifications are registered successfully
 */
- (void)test_push_types
{
    // Partial mock Action Manager.
    LPPushNotificationsManager *manager = [LPPushNotificationsManager sharedManager];
    id pushNotificationsManagerMock = OCMPartialMock(manager);
    OCMStub([LPPushNotificationsManager sharedManager]).andReturn(pushNotificationsManagerMock);
    OCMStub([pushNotificationsManagerMock respondsToSelector:
             @selector(leanplum_application:didRegisterForRemoteNotificationsWithDeviceToken:)]).andReturn(NO);

    // Remove Push Token.
    [manager removePushToken];
    
    [self removePushTypes];
    
    [self mockUserNotificationSettings];

    // TODO: separate token logic to be reused
    UIApplication *app = [UIApplication sharedApplication];
    XCTestExpectation *expectNewToken = [self expectationWithDescription:@"expectNewToken"];
    NSData *token = [@"sample" dataUsingEncoding:NSUTF8StringEncoding];
    NSString *formattedToken = [[LPNotificationsManager shared] hexadecimalStringFromData:token];
    formattedToken = [[[formattedToken stringByReplacingOccurrencesOfString:@"<" withString:@""]
                       stringByReplacingOccurrencesOfString:@">" withString:@""]
                      stringByReplacingOccurrencesOfString:@" " withString:@""];
    [LeanplumRequest validate_request:^BOOL(NSString *method, NSString *apiMethod,
                                            NSDictionary *params) {
        XCTAssertTrue([apiMethod isEqual:@"setDeviceAttributes"]);
        XCTAssertTrue([params[LP_PARAM_DEVICE_PUSH_TOKEN] isEqual:formattedToken]);
        XCTAssertTrue([params[LP_PARAM_DEVICE_USER_NOTIFICATION_TYPES] isEqual:@(UIUserNotificationTypeAlert)]);
        XCTAssertTrue([params[LP_PARAM_DEVICE_USER_NOTIFICATION_CATEGORIES] isEqual:[LPJSON stringFromJSON:@[@"testCategory"]?: @""]]);
        [expectNewToken fulfill];
        return YES;
    }];
    
    [manager leanplum_application:app didRegisterForRemoteNotificationsWithDeviceToken:token];
    
    // TODO: test categories will be sent even if token is the same
    // Test push token will not be sent with the same token.
    [LeanplumRequest validate_request:^BOOL(NSString *method, NSString *apiMethod,
                                            NSDictionary *params) {
        XCTAssertTrue(NO);
        return YES;
    }];
    [manager leanplum_application:app didRegisterForRemoteNotificationsWithDeviceToken:token];
    
    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)test_push_types_foreground
{
    [self removePushTypes];
    
    LPPushNotificationsManager *manager = [LPPushNotificationsManager sharedManager];
    id pushNotificationsManagerMock = OCMPartialMock(manager);
    OCMStub([LPPushNotificationsManager sharedManager]).andReturn(pushNotificationsManagerMock);

    __block int methodCalled = 0;
    OCMStub([[pushNotificationsManagerMock handler] sendUserNotificationSettingsIfChanged:[OCMArg any]])
    .andDo(^(NSInvocation *invocation)
    {
        methodCalled +=1;
    }).andForwardToRealObject();
    
    // Call start to attach the observer for App Resume/Foreground
    // Note that multiple start calls will attach multiple observers
    if (!Leanplum.hasStarted){
        XCTAssertTrue([LeanplumHelper start_production_test]);
    }

    // Mock Application Notification Settings
    [self mockUserNotificationSettings];
    
    XCTestExpectation *expectPushTypesSet = [self expectationWithDescription:@"expectPushTypesSet"];
    [LeanplumRequest validate_request:^BOOL(NSString *method, NSString *apiMethod,
                                            NSDictionary *params) {
        if ([apiMethod isEqual:@"setDeviceAttributes"]) {
            OCMVerify([[pushNotificationsManagerMock handler] sendUserNotificationSettingsIfChanged:[OCMArg any]]);
            XCTAssertTrue([params[LP_PARAM_DEVICE_USER_NOTIFICATION_TYPES] isEqual:@(UIUserNotificationTypeAlert)]);
            XCTAssertTrue([params[LP_PARAM_DEVICE_USER_NOTIFICATION_CATEGORIES] isEqual:[LPJSON stringFromJSON:@[@"testCategory"]?: @""]]);
            [expectPushTypesSet fulfill];
        }
        return YES;
    }];
    
    // Triggers sendUserNotificationSettingsIfChanged and resumeSession
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationWillEnterForegroundNotification
          object:nil];
    
    // Verify no request is made if the settings are the same
    [LeanplumRequest validate_request:^BOOL(NSString *method, NSString *apiMethod,
                                            NSDictionary *params) {
        if ([apiMethod isEqual:@"setDeviceAttributes"]) {
            XCTAssertTrue(NO);
        }
        return YES;
    }];
    
    // Triggers sendUserNotificationSettingsIfChanged and resumeSession
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationWillEnterForegroundNotification
          object:nil];
    
    OCMVerify([[pushNotificationsManagerMock handler] sendUserNotificationSettingsIfChanged:[OCMArg any]]);
    
    XCTAssertTrue(methodCalled == 2);
    [pushNotificationsManagerMock stopMocking];
    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)test_update_and_remove_push_token
{
    LPPushNotificationsManager *manager = [LPPushNotificationsManager sharedManager];
    
    NSString *token = @"test_token";
    [manager updatePushToken:token];
    XCTAssertEqual(token, [manager pushToken]);
    
    [manager removePushToken];
    XCTAssertNil([manager pushToken]);
}

- (void)test_disable_ask_to_ask
{
    //clean user defaults for key DEFAULTS_ASKED_TO_PUSH
    [[NSUserDefaults standardUserDefaults] removeObjectForKey: DEFAULTS_ASKED_TO_PUSH];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    LPPushNotificationsManager *manager = [LPPushNotificationsManager sharedManager];
    XCTAssertFalse([manager hasDisabledAskToAsk]);
    [manager disableAskToAsk];
    XCTAssertTrue([manager hasDisabledAskToAsk]);
}

@end
