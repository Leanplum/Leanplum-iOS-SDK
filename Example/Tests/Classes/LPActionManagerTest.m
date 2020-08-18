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
