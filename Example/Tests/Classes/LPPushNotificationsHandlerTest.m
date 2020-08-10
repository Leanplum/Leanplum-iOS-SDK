//
//  LPPushNotificationsHandlerTest.m
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

@interface LPPushNotificationsHandler (Test)
- (void)requireMessageContent:(NSString *)messageId
          withCompletionBlock:(LeanplumVariablesChangedBlock)onCompleted;
- (void)handleNotificationResponse:(NSDictionary *)userInfo
                 completionHandler:(LeanplumFetchCompletionBlock)completionHandler;
@end

@interface LPPushNotificationsHandlerTest : XCTestCase

@end

@implementation LPPushNotificationsHandlerTest

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

- (void)test_require_message_content
{
    // Vaidate request.
    [LPRequestSender validate_request:^(NSString *method, NSString *apiMethod,
                                        NSDictionary *params) {
        XCTAssertEqualObjects(apiMethod, @"getVars");
        XCTAssertEqual(params[@"includeMessageId"], @"messageId");
        return YES;
    }];
    [[LPPushNotificationsManager sharedManager].handler requireMessageContent:@"messageId" withCompletionBlock:nil];
}

- (void)test_notification_action
{
    id classMock = OCMClassMock([LPUIAlert class]);

    NSDictionary* userInfo = @{
                               @"_lpm": @"messageId",
                               @"_lpx": @"test_action",
                               @"aps" : @{@"alert": @"test"}};
    [[LPPushNotificationsManager sharedManager].handler
     maybePerformNotificationActions:userInfo
     action:nil
     active:YES];

    OCMVerify([classMock showWithTitle:APP_NAME
                               message:@"test"
                     cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                     otherButtonTitles:@[NSLocalizedString(@"View", nil)]
                                 block:OCMOCK_ANY]);
}

- (void) test_receive_notification
{
    NSDictionary* userInfo = @{
                               @"_lpm": @"messageId",
                               @"_lpx": @"test_action",
                               @"aps" : @{@"alert": @"test"}};

    XCTestExpectation* userNotificationCenterExpectation = [self expectationWithDescription:@"UNUserNotificationCenter_notification"];
    XCTestExpectation* applicationNotificationExpectation = [self expectationWithDescription:@"UIApplication_notification"];
    
    LPPushNotificationsHandler *handler = [[LPPushNotificationsHandler alloc] init];
    
    //test when UNUserNotificationCenter.currentNotificationCenter.delegate is set
    if (UNUserNotificationCenter.currentNotificationCenter.delegate != nil) {
        [handler handleNotificationResponse:userInfo completionHandler:^(LeanplumUIBackgroundFetchResult result) {
            [userNotificationCenterExpectation fulfill];
        }];
    }
    
    //test when UNUserNotificationCenter.currentNotificationCenter.delegate is nil
    UNUserNotificationCenter.currentNotificationCenter.delegate = nil;
    [handler didReceiveRemoteNotification:userInfo
                               withAction:@"test_action"
                   fetchCompletionHandler: ^(LeanplumUIBackgroundFetchResult result) {
                                            [applicationNotificationExpectation fulfill];
        
    }];
    
    [self waitForExpectationsWithTimeout:10 handler:nil];
}

@end
