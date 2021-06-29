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
#import <OHHTTPStubs/HTTPStubs.h>
#import <OHHTTPStubs/HTTPStubsPathHelpers.h>
#import "Leanplum+Extensions.h"
#import "LPActionManager.h"
#import "LeanplumHelper.h"
#import "LPRequestSender+Categories.h"
#import "LPNetworkEngine+Category.h"
#import "LPUIAlert.h"
#import "LPOperationQueue.h"

@interface LPActionManager (UnitTest)

@end

@interface LPActionManagerTest : XCTestCase

@end

@implementation LPActionManagerTest

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

- (void)test_matched_trigger_with_boolean_parameter
{
    LPActionManager *manager = [LPActionManager sharedManager];
    
    NSDictionary *config = @{@"whenLimits":@{@"children":@[],
                                             @"objects":@[],
                                             @"subjects":[NSNull null]
                                             },
                             @"whenTriggers":@{@"children":@[@{@"noun":@"boolParamValues",
                                                               @"objects":@[@"boolValue", @"false"],
                                                               @"subject":@"event",
                                                               @"verb":@"triggersWithParameter"
                                                               }],
                                               @"verb":@"OR"
                                               }
                             };
    
    // track parameters
    LPContextualValues *contextualValues = [[LPContextualValues alloc] init];
    
    contextualValues.parameters = @{@"boolValue":@NO};
    LeanplumMessageMatchResult result = [manager shouldShowMessage:@""
                                                        withConfig:config
                                                              when:@"event"
                                                     withEventName:@"boolParamValues"
                                                  contextualValues:contextualValues];
    XCTAssertTrue(result.matchedTrigger);
    
    contextualValues.parameters = @{@"boolValue":@"false"};
    result = [manager shouldShowMessage:@""
                                                        withConfig:config
                                                              when:@"event"
                                                     withEventName:@"boolParamValues"
                                                  contextualValues:contextualValues];
    XCTAssertTrue(result.matchedTrigger);
    
    contextualValues.parameters = @{@"boolValue":@"true"};
    result = [manager shouldShowMessage:@""
                                                        withConfig:config
                                                              when:@"event"
                                                     withEventName:@"boolParamValues"
                                                  contextualValues:contextualValues];
    XCTAssertFalse(result.matchedTrigger);
    
    contextualValues.parameters = @{@"boolValue":@YES};
    result = [manager shouldShowMessage:@""
                                                        withConfig:config
                                                              when:@"event"
                                                     withEventName:@"boolParamValues"
                                                  contextualValues:contextualValues];
    XCTAssertFalse(result.matchedTrigger);
}

- (void)test_active_period_false
{
    LPActionManager *manager = [LPActionManager sharedManager];
    LPContextualValues *contextualValues = [[LPContextualValues alloc] init];
    
    NSDictionary *config = [self messageConfigInActivePeriod:NO];

    LeanplumMessageMatchResult result = [manager shouldShowMessage:@""
                                                        withConfig:config
                                                              when:@"event"
                                                     withEventName:@"ActivePeriodTest"
                                                  contextualValues:contextualValues];
    XCTAssertFalse(result.matchedActivePeriod);
}

- (void)test_active_period_true
{
    LPActionManager *manager = [LPActionManager sharedManager];
    LPContextualValues *contextualValues = [[LPContextualValues alloc] init];

    NSDictionary *config = [self messageConfigInActivePeriod:YES];
    
    LeanplumMessageMatchResult result = [manager shouldShowMessage:@""
                                                        withConfig:config
                                                              when:@"event"
                                                     withEventName:@"ActivePeriodTest"
                                                  contextualValues:contextualValues];
    XCTAssertTrue(result.matchedActivePeriod);

}

- (void)testShouldSuppressMessagesSessionLimit
{
    id<HTTPStubsDescriptor> startStub = [HTTPStubs stubRequestsPassingTest:
                                           ^BOOL(NSURLRequest * _Nonnull request) {
        return [request.URL.host isEqualToString:API_HOST];
    } withStubResponse:^HTTPStubsResponse * _Nonnull(NSURLRequest * _Nonnull request) {
        NSString *response_file = OHPathForFile(@"local_caps_session_response.json", self.class);
        return [HTTPStubsResponse responseWithFileAtPath:response_file statusCode:200
                                                   headers:@{@"Content-Type":@"application/json"}];
    }];
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    [Leanplum startWithResponseHandler:^(BOOL success) {
        [HTTPStubs removeStub:startStub];
        if (success) {
            dispatch_semaphore_signal(semaphore);
        }
        
    }];
    long timedOut = dispatch_semaphore_wait(semaphore, [LeanplumHelper default_dispatch_time]);
    if (timedOut > 0) {
        NSLog(@"test failed");
        XCTFail(@"timed out");
    }
    
    for (int i = 1; i<=5; i++) {
        NSString *prefix = [NSString stringWithFormat:LEANPLUM_DEFAULTS_MESSAGE_IMPRESSION_OCCURRENCES_KEY, @""];
        NSString *key = [NSString stringWithFormat:@"%@message#%d", prefix, i];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:key];
    }
    
    [[LPActionManager sharedManager] recordMessageImpression:@"message#1"];
    [[LPActionManager sharedManager] recordMessageImpression:@"message#2"];
    XCTAssertFalse([[LPActionManager sharedManager] shouldSuppressMessages]);
    
    [[LPActionManager sharedManager] recordMessageImpression:@"message#3"];
    [[LPActionManager sharedManager] recordMessageImpression:@"message#4"];
    XCTAssertFalse([[LPActionManager sharedManager] shouldSuppressMessages]);
    
    [[LPActionManager sharedManager] recordMessageImpression:@"message#5"];
    XCTAssertTrue([[LPActionManager sharedManager] shouldSuppressMessages]);
}

- (void)testShouldSuppressMessagesDayLimit
{
    id<HTTPStubsDescriptor> startStub = [HTTPStubs stubRequestsPassingTest:
                                           ^BOOL(NSURLRequest * _Nonnull request) {
        return [request.URL.host isEqualToString:API_HOST];
    } withStubResponse:^HTTPStubsResponse * _Nonnull(NSURLRequest * _Nonnull request) {
        NSString *response_file = OHPathForFile(@"local_caps_day_response.json", self.class);
        return [HTTPStubsResponse responseWithFileAtPath:response_file statusCode:200
                                                   headers:@{@"Content-Type":@"application/json"}];
    }];
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    [Leanplum startWithResponseHandler:^(BOOL success) {
        [HTTPStubs removeStub:startStub];
        if (success) {
            dispatch_semaphore_signal(semaphore);
        }
        
    }];
    long timedOut = dispatch_semaphore_wait(semaphore, [LeanplumHelper default_dispatch_time]);
    if (timedOut > 0) {
        NSLog(@"test failed");
        XCTFail(@"timed out");
    }
    for (int i = 1; i<=5; i++) {
        NSString *prefix = [NSString stringWithFormat:LEANPLUM_DEFAULTS_MESSAGE_IMPRESSION_OCCURRENCES_KEY, @""];
        NSString *key = [NSString stringWithFormat:@"%@message#%d", prefix, i];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:key];
    }
    
    [[LPActionManager sharedManager] recordMessageImpression:@"message#1"];
    [[LPActionManager sharedManager] recordMessageImpression:@"message#1"];
    [[LPActionManager sharedManager] recordMessageImpression:@"message#1"];
    [[LPActionManager sharedManager] recordMessageImpression:@"message#1"];
    [[LPActionManager sharedManager] recordMessageImpression:@"message#1"];
    XCTAssertFalse([[LPActionManager sharedManager] shouldSuppressMessages]);
    
    [[LPActionManager sharedManager] recordMessageImpression:@"message#2"];
    [[LPActionManager sharedManager] recordMessageImpression:@"message#2"];
    [[LPActionManager sharedManager] recordMessageImpression:@"message#2"];
    [[LPActionManager sharedManager] recordMessageImpression:@"message#2"];
    [[LPActionManager sharedManager] recordMessageImpression:@"message#2"];
    XCTAssertFalse([[LPActionManager sharedManager] shouldSuppressMessages]);
    
    [[LPActionManager sharedManager] recordMessageImpression:@"message#3"];
    [[LPActionManager sharedManager] recordMessageImpression:@"message#3"];
    [[LPActionManager sharedManager] recordMessageImpression:@"message#3"];
    [[LPActionManager sharedManager] recordMessageImpression:@"message#3"];
    [[LPActionManager sharedManager] recordMessageImpression:@"message#3"];
    XCTAssertFalse([[LPActionManager sharedManager] shouldSuppressMessages]);
    
    [[LPActionManager sharedManager] recordMessageImpression:@"message#4"];
    [[LPActionManager sharedManager] recordMessageImpression:@"message#4"];
    [[LPActionManager sharedManager] recordMessageImpression:@"message#4"];
    [[LPActionManager sharedManager] recordMessageImpression:@"message#4"];
    [[LPActionManager sharedManager] recordMessageImpression:@"message#4"];
    XCTAssertFalse([[LPActionManager sharedManager] shouldSuppressMessages]);
    
    [[LPActionManager sharedManager] recordMessageImpression:@"message#5"];
    [[LPActionManager sharedManager] recordMessageImpression:@"message#5"];
    [[LPActionManager sharedManager] recordMessageImpression:@"message#5"];
    [[LPActionManager sharedManager] recordMessageImpression:@"message#5"];
    XCTAssertFalse([[LPActionManager sharedManager] shouldSuppressMessages]);
    
    [[LPActionManager sharedManager] recordMessageImpression:@"message#5"];
    XCTAssertTrue([[LPActionManager sharedManager] shouldSuppressMessages]);
}

- (void)testShouldSuppressMessagesWeekLimit
{
    id<HTTPStubsDescriptor> startStub = [HTTPStubs stubRequestsPassingTest:
                                           ^BOOL(NSURLRequest * _Nonnull request) {
        return [request.URL.host isEqualToString:API_HOST];
    } withStubResponse:^HTTPStubsResponse * _Nonnull(NSURLRequest * _Nonnull request) {
        NSString *response_file = OHPathForFile(@"local_caps_week_response.json", self.class);
        return [HTTPStubsResponse responseWithFileAtPath:response_file statusCode:200
                                                   headers:@{@"Content-Type":@"application/json"}];
    }];
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    [Leanplum startWithResponseHandler:^(BOOL success) {
        [HTTPStubs removeStub:startStub];
        if (success) {
            dispatch_semaphore_signal(semaphore);
        }
        
    }];
    long timedOut = dispatch_semaphore_wait(semaphore, [LeanplumHelper default_dispatch_time]);
    if (timedOut > 0) {
        NSLog(@"test failed");
        XCTFail(@"timed out");
    }
    for (int i = 1; i<=5; i++) {
        NSString *prefix = [NSString stringWithFormat:LEANPLUM_DEFAULTS_MESSAGE_IMPRESSION_OCCURRENCES_KEY, @""];
        NSString *key = [NSString stringWithFormat:@"%@message#%d", prefix, i];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:key];
    }
    
    for (int i = 1; i<=5; i++) {
        NSString *messageId = [NSString stringWithFormat:@"message#%d", i];
        for (int j = 0; j < 20; j++) {
            [[LPActionManager sharedManager] recordMessageImpression:messageId];
        }
        if (i == 5) {
            XCTAssertTrue([[LPActionManager sharedManager] shouldSuppressMessages]);
        } else {
            XCTAssertFalse([[LPActionManager sharedManager] shouldSuppressMessages]);
        }
    }
}

#pragma mark Helpers

-(NSDictionary *)messageConfigInActivePeriod:(BOOL)inActivePeriod
{
    NSDictionary *config = @{@"whenLimits":@{@"children":@[]},
                             @"whenTriggers":@{@"children":@[@{@"noun":@"ActivePeriodTest",
                                                               @"subject":@"event",
                                                               }],
                                               @"verb":@"OR"
                                               },
                             @"startTime": inActivePeriod ? @1524507600000 : @956557100000,
                             @"endTime": inActivePeriod ? @7836202020000 : @956557200000
                             };
    return config;
}

@end
