//
//  LPActionTriggerManager.m
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
#import <OHHTTPStubs/HTTPStubsResponse+JSON.h>
#import <Leanplum/LPActionTriggerManager.h>
#import <Leanplum/LPOperationQueue.h>
#import "Leanplum+Extensions.h"
#import "LeanplumHelper.h"
#import "LPRequestSender+Categories.h"
#import "LPRequestFactory+Extension.h"
#import "LPNetworkEngine+Category.h"

@interface LPActionTriggerManagerTest : XCTestCase

@end

@interface LPActionTriggerManager(Test)

- (void)recordImpression:(NSString *)messageId;

@end

@implementation LPActionTriggerManagerTest

- (void)tearDown
{
    [super tearDown];
    // Clear message impressions
    for (int i = 1; i<=5; i++) {
        NSString *prefix = [NSString stringWithFormat:LEANPLUM_DEFAULTS_MESSAGE_IMPRESSION_OCCURRENCES_KEY, @""];
        NSString *key = [NSString stringWithFormat:@"%@message#%d", prefix, i];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:key];
    }
    [LPActionTriggerManager reset];
}

+ (void)tearDown {
    [super tearDown];
    [[LPVarCache sharedCache] applyVariableDiffs:@{}
                                        messages:@{}
                                        variants:@[]
                                       localCaps:@[]
                                         regions:@{}
                                variantDebugInfo:@{}
                                        varsJson:@""
                                   varsSignature:@""];
}

- (void)test_matched_trigger
{
    LPActionTriggerManager *manager = [LPActionTriggerManager sharedManager];

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
    LPActionTriggerManager *manager = [LPActionTriggerManager sharedManager];
    
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
    LPActionTriggerManager *manager = [LPActionTriggerManager sharedManager];
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
    LPActionTriggerManager *manager = [LPActionTriggerManager sharedManager];
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
    NSArray *localCaps = @[
        @{
            @"channel": @"IN_APP",
            @"limit": @5,
            @"type": @"SESSION"
        }
    ];

    [[LPVarCache sharedCache] applyVariableDiffs:@{}
                                        messages:@{}
                                        variants:@[]
                                       localCaps:localCaps
                                         regions:@{}
                                variantDebugInfo:@{}
                                        varsJson:@""
                                   varsSignature:@""];
    
    [[LPActionTriggerManager sharedManager] recordImpression:@"message#1"];
    [[LPActionTriggerManager sharedManager] recordImpression:@"message#2"];
    XCTAssertFalse([[LPActionTriggerManager sharedManager] shouldSuppressMessages]);
    
    [[LPActionTriggerManager sharedManager] recordImpression:@"message#3"];
    [[LPActionTriggerManager sharedManager] recordImpression:@"message#4"];
    XCTAssertFalse([[LPActionTriggerManager sharedManager] shouldSuppressMessages]);
    
    [[LPActionTriggerManager sharedManager] recordImpression:@"message#5"];
    XCTAssertTrue([[LPActionTriggerManager sharedManager] shouldSuppressMessages]);
}

- (void)testShouldSuppressMessagesDayLimit
{
    NSArray *localCaps = @[
        @{
            @"channel": @"IN_APP",
            @"limit": @25,
            @"type": @"DAY"
        }
    ];
    
    [[LPVarCache sharedCache] applyVariableDiffs:@{}
                                        messages:@{}
                                        variants:@[]
                                       localCaps:localCaps
                                         regions:@{}
                                variantDebugInfo:@{}
                                        varsJson:@""
                                   varsSignature:@""];
    
    [[LPActionTriggerManager sharedManager] recordImpression:@"message#1"];
    [[LPActionTriggerManager sharedManager] recordImpression:@"message#1"];
    [[LPActionTriggerManager sharedManager] recordImpression:@"message#1"];
    [[LPActionTriggerManager sharedManager] recordImpression:@"message#1"];
    [[LPActionTriggerManager sharedManager] recordImpression:@"message#1"];
    XCTAssertFalse([[LPActionTriggerManager sharedManager] shouldSuppressMessages]);
    
    [[LPActionTriggerManager sharedManager] recordImpression:@"message#2"];
    [[LPActionTriggerManager sharedManager] recordImpression:@"message#2"];
    [[LPActionTriggerManager sharedManager] recordImpression:@"message#2"];
    [[LPActionTriggerManager sharedManager] recordImpression:@"message#2"];
    [[LPActionTriggerManager sharedManager] recordImpression:@"message#2"];
    XCTAssertFalse([[LPActionTriggerManager sharedManager] shouldSuppressMessages]);
    
    [[LPActionTriggerManager sharedManager] recordImpression:@"message#3"];
    [[LPActionTriggerManager sharedManager] recordImpression:@"message#3"];
    [[LPActionTriggerManager sharedManager] recordImpression:@"message#3"];
    [[LPActionTriggerManager sharedManager] recordImpression:@"message#3"];
    [[LPActionTriggerManager sharedManager] recordImpression:@"message#3"];
    XCTAssertFalse([[LPActionTriggerManager sharedManager] shouldSuppressMessages]);
    
    [[LPActionTriggerManager sharedManager] recordImpression:@"message#4"];
    [[LPActionTriggerManager sharedManager] recordImpression:@"message#4"];
    [[LPActionTriggerManager sharedManager] recordImpression:@"message#4"];
    [[LPActionTriggerManager sharedManager] recordImpression:@"message#4"];
    [[LPActionTriggerManager sharedManager] recordImpression:@"message#4"];
    XCTAssertFalse([[LPActionTriggerManager sharedManager] shouldSuppressMessages]);
    
    [[LPActionTriggerManager sharedManager] recordImpression:@"message#5"];
    [[LPActionTriggerManager sharedManager] recordImpression:@"message#5"];
    [[LPActionTriggerManager sharedManager] recordImpression:@"message#5"];
    [[LPActionTriggerManager sharedManager] recordImpression:@"message#5"];
    XCTAssertFalse([[LPActionTriggerManager sharedManager] shouldSuppressMessages]);
    
    [[LPActionTriggerManager sharedManager] recordImpression:@"message#5"];
    XCTAssertTrue([[LPActionTriggerManager sharedManager] shouldSuppressMessages]);
}

- (void)testShouldSuppressMessagesWeekLimit
{
    NSArray *localCaps = @[
        @{
          @"channel": @"IN_APP",
          @"limit": @100,
          @"type": @"WEEK"
        }
    ];
    
    [[LPVarCache sharedCache] applyVariableDiffs:@{}
                                        messages:@{}
                                        variants:@[]
                                       localCaps:localCaps
                                         regions:@{}
                                variantDebugInfo:@{}
                                        varsJson:@""
                                   varsSignature:@""];
    
    for (int i = 1; i<=5; i++) {
        NSString *messageId = [NSString stringWithFormat:@"message#%d", i];
        for (int j = 0; j < 20; j++) {
            [[LPActionTriggerManager sharedManager] recordImpression:messageId];
        }
        if (i == 5) {
            XCTAssertTrue([[LPActionTriggerManager sharedManager] shouldSuppressMessages]);
        } else {
            XCTAssertFalse([[LPActionTriggerManager sharedManager] shouldSuppressMessages]);
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
