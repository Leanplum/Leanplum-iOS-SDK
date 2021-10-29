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
#import "Leanplum+Extensions.h"
#import "LPRequestSender+Categories.h"
#import "LPNetworkEngine+Category.h"
#import <Leanplum/LPUIAlert.h>
#import <Leanplum/LPOperationQueue.h>
#import <Leanplum/LPPushNotificationsManager.h>
#import <Leanplum/LPNotificationsManager.h>

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
}

- (void)tearDown
{
    [super tearDown];
    [LeanplumHelper clean_up];
}

- (LPPushNotificationsManager*)mockManager
{
    LPPushNotificationsManager *manager = [LPPushNotificationsManager sharedManager];
    id pushNotificationsManagerMock = OCMPartialMock(manager);
    OCMStub([LPPushNotificationsManager sharedManager]).andReturn(pushNotificationsManagerMock);
    OCMStub([pushNotificationsManagerMock respondsToSelector:
             @selector(leanplum_application:didRegisterForRemoteNotificationsWithDeviceToken:)]).andReturn(NO);
    return manager;
}

- (NSString*)formatToken:(NSData*)token
{
    NSString *formattedToken = [[LPNotificationsManager shared] hexadecimalStringFromData:token];
    formattedToken = [[[formattedToken stringByReplacingOccurrencesOfString:@"<" withString:@""]
                       stringByReplacingOccurrencesOfString:@">" withString:@""]
                      stringByReplacingOccurrencesOfString:@" " withString:@""];
    return formattedToken;
}

- (void)removePushTypes
{
    NSString *settingsKey = [[LPPushNotificationsManager sharedManager] leanplum_createUserNotificationSettingsKey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:settingsKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)mockUserNotificationSettings:(UIUserNotificationType)type withCategoryId:(NSString *)categoryId
{
    id mockApplication = OCMClassMock([UIApplication class]);
    OCMStub([mockApplication sharedApplication]).andReturn(mockApplication);
    UIMutableUserNotificationCategory *cat = [[UIMutableUserNotificationCategory alloc] init];
    cat.identifier = categoryId;
    UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:type categories:[NSSet setWithObject:cat]];
    OCMStub([mockApplication currentUserNotificationSettings]).andReturn(settings);
}

- (void)test_push_token
{
    XCTAssertTrue([LeanplumHelper start_production_test]);

    // Partial mock Action Manager.
    LPPushNotificationsManager *manager = [self mockManager];

    // Remove Push Token.
    [manager removePushToken];

    // Test push token is sent on clean start.
    XCTestExpectation *expectNewToken = [self expectationWithDescription:@"expectNewToken"];
    NSData *token = [@"sample" dataUsingEncoding:NSUTF8StringEncoding];
    [LPRequestSender validate_request:^BOOL(NSString *method, NSString *apiMethod,
                                            NSDictionary *params) {
        XCTAssertTrue([apiMethod isEqual:@"setDeviceAttributes"]);
        XCTAssertTrue([params[@"iosPushToken"] isEqual:[self formatToken:token]]);
        [expectNewToken fulfill];
        return YES;
    }];

    [[manager handler] didRegisterForRemoteNotificationsWithDeviceToken:token];
    [self waitForExpectationsWithTimeout:2 handler:nil];

    // Test push token will not be sent with the same token.
    [LPRequestSender validate_request:^BOOL(NSString *method, NSString *apiMethod,
                                            NSDictionary *params) {
        XCTAssertTrue(NO);
        return YES;
    }];

    [[manager handler] didRegisterForRemoteNotificationsWithDeviceToken:token];

    // Test push token is sent if the token changes.
    token = [@"sample2" dataUsingEncoding:NSUTF8StringEncoding];
    XCTestExpectation *expectUpdatedToken = [self expectationWithDescription:@"expectUpdatedToken"];
    [LPRequestSender validate_request:^BOOL(NSString *method, NSString *apiMethod,
                                            NSDictionary *params) {
        XCTAssertTrue([apiMethod isEqual:@"setDeviceAttributes"]);
        XCTAssertTrue([params[LP_PARAM_DEVICE_PUSH_TOKEN] isEqual:[self formatToken:token]]);
        [expectUpdatedToken fulfill];
        return YES;
    }];

    [[manager handler] didRegisterForRemoteNotificationsWithDeviceToken:token];
    [[LPOperationQueue serialQueue] waitUntilAllOperationsAreFinished];
    [self waitForExpectationsWithTimeout:2 handler:nil];
}

/**
 * Test iOS Push Types are sent when notifications are registered successfully
 */
- (void)test_push_types_new_token
{
    // Partial mock Action Manager.
    LPPushNotificationsManager *manager = [self mockManager];

    // Remove Push Token.
    [manager removePushToken];
    [self removePushTypes];
    
    if (!Leanplum.hasStarted){
        XCTAssertTrue([LeanplumHelper start_production_test]);
    }
    
    [self mockUserNotificationSettings:UIUserNotificationTypeAlert withCategoryId:@"testCategory"];

    XCTestExpectation *expectNewToken = [self expectationWithDescription:@"expectNewToken"];
    NSData *token = [@"sample" dataUsingEncoding:NSUTF8StringEncoding];
    
    [LPRequestSender validate_request:^BOOL(NSString *method, NSString *apiMethod,
                                            NSDictionary *params) {
        XCTAssertTrue([apiMethod isEqual:@"setDeviceAttributes"]);
        XCTAssertTrue([params[LP_PARAM_DEVICE_PUSH_TOKEN] isEqual:[self formatToken:token]]);
        XCTAssertTrue([params[LP_PARAM_DEVICE_USER_NOTIFICATION_TYPES] isEqual:@(UIUserNotificationTypeAlert)]);
        XCTAssertTrue([params[LP_PARAM_DEVICE_USER_NOTIFICATION_CATEGORIES] isEqual:[LPJSON stringFromJSON:@[@"testCategory"]?: @""]]);
        [expectNewToken fulfill];
        return YES;
    }];
    
    [[manager handler] didRegisterForRemoteNotificationsWithDeviceToken:token];
    
    [self waitForExpectationsWithTimeout:2 handler:nil];
}

/**
 * Test iOS Push Types are sent when notifications are registered successfully and token is the same
 */
- (void)test_push_types_same_token
{
    // Partial mock Action Manager.
    LPPushNotificationsManager *manager = [self mockManager];
    [self removePushTypes];
    
    [self mockUserNotificationSettings:UIUserNotificationTypeAlert withCategoryId:@"testCategory"];

    XCTestExpectation *expectPushTypes = [self expectationWithDescription:@"expectPushTypes"];
    
    if (!Leanplum.hasStarted){
        XCTAssertTrue([LeanplumHelper start_production_test]);
    }
    
    // Ensure the same token
    NSString *pushToken = @"testToken";
    NSData *token = [pushToken dataUsingEncoding:NSUTF8StringEncoding];
    NSString *formattedToken = [self formatToken:token];
    [manager updatePushToken:formattedToken];
    
    [LPRequestSender validate_request:^BOOL(NSString *method, NSString *apiMethod,
                                            NSDictionary *params) {
        XCTAssertTrue([apiMethod isEqual:@"setDeviceAttributes"]);
        XCTAssertNil(params[LP_PARAM_DEVICE_PUSH_TOKEN]);
        XCTAssertTrue([params[LP_PARAM_DEVICE_USER_NOTIFICATION_TYPES] isEqual:@(UIUserNotificationTypeAlert)]);
        XCTAssertTrue([params[LP_PARAM_DEVICE_USER_NOTIFICATION_CATEGORIES] isEqual:[LPJSON stringFromJSON:@[@"testCategory"]?: @""]]);
        [expectPushTypes fulfill];
        return YES;
    }];
    
    [[manager handler] didRegisterForRemoteNotificationsWithDeviceToken:token];
    
    [self waitForExpectationsWithTimeout:2 handler:nil];
}

/**
 * Test iOS Push token /and types/ are sent after Leanplum has started
 * This will prevent creating the request with empty userId and deviceId
 */
- (void)test_push_token_not_before_start
{
    // Partial mock Action Manager.
    LPPushNotificationsManager *manager = [self mockManager];

    // Remove Push Token.
    [manager removePushToken];
    
    if (!Leanplum.hasStarted){
        NSData *token = [@"sample" dataUsingEncoding:NSUTF8StringEncoding];
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        [LPRequestSender validate_request:^BOOL(NSString *method, NSString *apiMethod,
                                                NSDictionary *params) {
            if ([apiMethod isEqual:@"setDeviceAttributes"]) {
                XCTAssertTrue(NO);
                dispatch_semaphore_signal(semaphore);
            }
        }];
        
        [[manager handler] didRegisterForRemoteNotificationsWithDeviceToken:token];
        
        long timedOut = dispatch_semaphore_wait(semaphore, [LeanplumHelper default_dispatch_time]);
        // Expect to timeout since the request should never be made, but still wait to verify it is not
        XCTAssertTrue(timedOut > 0);
    }
}

- (void)test_push_types_foreground
{
    [self removePushTypes];
    
    LPPushNotificationsManager *manager = [LPPushNotificationsManager sharedManager];
    id pushNotificationsManagerMock = OCMPartialMock(manager);
    OCMStub([LPPushNotificationsManager sharedManager]).andReturn(pushNotificationsManagerMock);
    
    // Call start to attach the observer for App Resume/Foreground
    // Note that multiple start calls will attach multiple observers
    if (!Leanplum.hasStarted){
        XCTAssertTrue([LeanplumHelper start_production_test]);
    }

    // Mock Application Notification Settings
    [self mockUserNotificationSettings:UIUserNotificationTypeAlert withCategoryId:@"testCategory"];
    
    XCTestExpectation *expectPushTypesSet = [self expectationWithDescription:@"expectPushTypesSet"];
    [LPRequestSender validate_request:^BOOL(NSString *method, NSString *apiMethod,
                                            NSDictionary *params) {
        if ([apiMethod isEqual:@"setDeviceAttributes"]) {
            // Use the mock object to verify
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
    [LPRequestSender validate_request:^BOOL(NSString *method, NSString *apiMethod,
                                            NSDictionary *params) {
        if ([apiMethod isEqual:@"setDeviceAttributes"]) {
            XCTAssertTrue(NO);
        }
        return YES;
    }];
    
    // Triggers sendUserNotificationSettingsIfChanged and resumeSession
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationWillEnterForegroundNotification
          object:nil];
    // Use the mock object to verify
    OCMVerify([[pushNotificationsManagerMock handler] sendUserNotificationSettingsIfChanged:[OCMArg any]]);
    
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
