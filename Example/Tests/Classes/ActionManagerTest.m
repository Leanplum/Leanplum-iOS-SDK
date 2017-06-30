//
//  LPActionManagerTest.m
//  Leanplum
//
//  Created by Alexis Oyama on 11/3/16.
//  Copyright (c) 2016 Leanplum. All rights reserved.
//
//  Licensed to the Apache Software Foundation (ASF) under one
//  or more contributor license agreements.  See the NOTICE file
//  distributed with this work for additional information
//  regarding copyright ownership.  The ASF licenses this file
//  to you under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing,
//  software distributed under the License is distributed on an
//  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
//  KIND, either express or implied.  See the License for the
//  specific language governing permissions and limitations
//  under the License.


#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import <OHHTTPStubs/OHHTTPStubs.h>
#import <OHHTTPStubs/OHPathHelpers.h>
#import "LPActionManager.h"
#import "LeanplumHelper.h"
#import "LeanplumRequest+Categories.h"
#import "LPNetworkEngine+Category.h"
#import "Leanplum+Extensions.h"
#import "LPUIAlert.h"

@interface LPActionManager (Test)
- (void)requireMessageContent:(NSString *)messageId
          withCompletionBlock:(LeanplumVariablesChangedBlock)onCompleted;
+ (NSString *)messageIdFromUserInfo:(NSDictionary *)userInfo;
- (void)sendUserNotificationSettingsIfChanged:(UIUserNotificationSettings *)notificationSettings;
- (void)didReceiveRemoteNotification:(NSDictionary *)userInfo
                          withAction:(NSString *)action
              fetchCompletionHandler:(LeanplumFetchCompletionBlock)completionHandler;
@end

@interface ActionManagerTest : XCTestCase

@end

@implementation ActionManagerTest

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

- (void)test_matched_trigger
{
    LPActionManager *manager = [LPActionManager sharedManager];

    // Message Object
    NSDictionary *config = @{@"whenLimits":@{@"children":@[],
                                             @"objects":@[],
                                             @"subjects":[NSNull null]
                                             },
                             @"whenTriggers":@{@"children":@[@{@"noun":@"Sick",
                                                               @"objects":@[@"symptom", @"cough"],
                                                               @"subject":@"event",
                                                               @"verb":@"triggersWithParameter"
                                                               }],
                                               @"verb":@"OR"
                                               }
                             };

    // track parameters
    LPContextualValues *contextualValues = [[LPContextualValues alloc] init];

    // [Leanplum track:@"Sick"]
    contextualValues.parameters = @{};
    LeanplumMessageMatchResult result = [manager shouldShowMessage:@""
                                                        withConfig:config
                                                              when:@"event"
                                                     withEventName:@"Sick"
                                                  contextualValues:contextualValues];
    XCTAssertFalse(result.matchedTrigger);

    // [Leanplum track:@"Sick" withParameters:@{@"symptom":@""}]
    contextualValues.parameters = @{@"symptom":@""};
    result = [manager shouldShowMessage:@""
                             withConfig:config
                                   when:@"event"
                          withEventName:@"Sick"
                       contextualValues:contextualValues];
    XCTAssertFalse(result.matchedTrigger);

    // [Leanplum track:@"Sick" withParameters:@{@"test":@"test"}]
    contextualValues.parameters = @{@"test":@"test"};
    result = [manager shouldShowMessage:@""
                             withConfig:config
                                   when:@"event"
                          withEventName:@"Sick"
                       contextualValues:contextualValues];
    XCTAssertFalse(result.matchedTrigger);

    // [Leanplum track:@"Sick" withParameters:@{@"symptom":@"cough"}]
    contextualValues.parameters = @{@"symptom":@"cough"};
    result = [manager shouldShowMessage:@""
                             withConfig:config
                                   when:@"event"
                          withEventName:@"Sick"
                       contextualValues:contextualValues];
    XCTAssertTrue(result.matchedTrigger);
    
    // [Leanplum track:@"Sick" withParameters:nil
    contextualValues.parameters = nil;
    result = [manager shouldShowMessage:@""
                             withConfig:config
                                   when:@"event"
                          withEventName:@"Sick"
                       contextualValues:contextualValues];
    XCTAssertFalse(result.matchedTrigger);
    
    // [Leanplum track:@"NotSick" withParameters:@{@"symptom":@"cough"}]
    contextualValues.parameters = @{@"symptom":@"cough"};
    result = [manager shouldShowMessage:@""
                             withConfig:config
                                   when:@"event"
                          withEventName:@"NotSick"
                       contextualValues:contextualValues];
    XCTAssertFalse(result.matchedTrigger);
}

- (void)test_require_message_content
{
    // This stub have to be removed when start command is successfully executed.
    [OHHTTPStubs stubRequestsPassingTest:
     ^BOOL(NSURLRequest * _Nonnull request) {
         return [request.URL.host isEqualToString:API_HOST];
     } withStubResponse:^OHHTTPStubsResponse * _Nonnull(NSURLRequest * _Nonnull request) {
         NSString *response_file = OHPathForFile(@"simple_start_response.json", self.class);
         return [OHHTTPStubsResponse responseWithFileAtPath:response_file statusCode:200
                                                    headers:@{@"Content-Type":@"application/json"}];
     }];
    
    XCTAssertTrue([LeanplumHelper start_development_test]);
    
    // Vaidate request.
    [LeanplumRequest validate_request:^(NSString *method, NSString *apiMethod,
                                        NSDictionary *params) {
        XCTAssertEqualObjects(apiMethod, @"getVars");
        XCTAssertEqual(params[@"includeMessageId"], @"messageId");
        return YES;
    }];
    [[LPActionManager sharedManager] requireMessageContent:@"messageId" withCompletionBlock:nil];
}

- (void)test_notification_action
{
    id classMock = OCMClassMock([LPUIAlert class]);
    
    NSDictionary* userInfo = @{
                               @"_lpm": @"messageId",
                               @"_lpx": @"test_action",
                               @"aps" : @{@"alert": @"test"}};
    [[LPActionManager sharedManager] maybePerformNotificationActions:userInfo
                                                              action:nil
                                                              active:YES];
    
    OCMVerify([classMock showWithTitle:OCMOCK_ANY
                               message:OCMOCK_ANY
                     cancelButtonTitle:OCMOCK_ANY
                     otherButtonTitles:OCMOCK_ANY
                                 block:OCMOCK_ANY]);
}

- (void) test_receive_notification
{
    // This stub have to be removed when start command is successfully executed.
    [OHHTTPStubs stubRequestsPassingTest:
     ^BOOL(NSURLRequest * _Nonnull request) {
         return [request.URL.host isEqualToString:API_HOST];
     } withStubResponse:^OHHTTPStubsResponse * _Nonnull(NSURLRequest * _Nonnull request) {
         NSString *response_file = OHPathForFile(@"simple_start_response.json", self.class);
         return [OHHTTPStubsResponse responseWithFileAtPath:response_file statusCode:200
                                                    headers:@{@"Content-Type":@"application/json"}];
     }];
    
    XCTAssertTrue([LeanplumHelper start_development_test]);
    
    NSDictionary* userInfo = @{
                               @"_lpm": @"messageId",
                               @"_lpx": @"test_action",
                               @"aps" : @{@"alert": @"test"}};
    
    XCTestExpectation* expectation = [self expectationWithDescription:@"notification"];
    
    [[LPActionManager sharedManager] didReceiveRemoteNotification:userInfo
                                                       withAction:@"test_action"
                                           fetchCompletionHandler:
     ^(LeanplumUIBackgroundFetchResult result) {
         [expectation fulfill];
     }];
    [self waitForExpectationsWithTimeout:10 handler:nil];
}

- (void)test_messageId_from_userinfo
{
    NSDictionary *userInfo = nil;
    NSString* messageId = nil;
    
    userInfo = @{@"_lpm": @"messageId"};
    messageId = [LPActionManager messageIdFromUserInfo:userInfo];
    XCTAssertEqual(messageId, @"messageId");
    
    userInfo = @{@"_lpu": @"messageId"};
    messageId = [LPActionManager messageIdFromUserInfo:userInfo];
    XCTAssertEqual(messageId, @"messageId");
    
    userInfo = @{@"_lpn": @"messageId"};
    messageId = [LPActionManager messageIdFromUserInfo:userInfo];
    XCTAssertEqual(messageId, @"messageId");
    
    userInfo = @{@"_lpv": @"messageId"};
    messageId = [LPActionManager messageIdFromUserInfo:userInfo];
    XCTAssertEqual(messageId, @"messageId");
}
@end
