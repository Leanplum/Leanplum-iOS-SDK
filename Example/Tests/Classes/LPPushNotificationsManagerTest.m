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
    [LeanplumHelper setup_development_test];
}

- (void)tearDown
{
    [super tearDown];
    [LeanplumHelper clean_up];
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
    [LPRequestSender validate_request:^BOOL(NSString *method, NSString *apiMethod,
                                            NSDictionary *params) {
        XCTAssertTrue([apiMethod isEqual:@"setDeviceAttributes"]);
        XCTAssertTrue([params[@"iosPushToken"] isEqual:formattedToken]);
        [expectNewToken fulfill];
        return YES;
    }];
    [manager leanplum_application:app didRegisterForRemoteNotificationsWithDeviceToken:token];
    [self waitForExpectationsWithTimeout:2 handler:nil];

    // Test push token will not be sent with the same token.
    [LPRequestSender validate_request:^BOOL(NSString *method, NSString *apiMethod,
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
    [LPRequestSender validate_request:^BOOL(NSString *method, NSString *apiMethod,
                                            NSDictionary *params) {
        XCTAssertTrue([apiMethod isEqual:@"setDeviceAttributes"]);
        XCTAssertTrue([params[@"iosPushToken"] isEqual:formattedToken]);
        [expectUpdatedToken fulfill];
        return YES;
    }];
    [manager leanplum_application:app didRegisterForRemoteNotificationsWithDeviceToken:token];
    [[LPOperationQueue serialQueue] waitUntilAllOperationsAreFinished];
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
