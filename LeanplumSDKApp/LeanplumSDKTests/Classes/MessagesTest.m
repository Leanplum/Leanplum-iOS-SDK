//
//  LPInAppMessagePrioritizationTest.m
//  Leanplum
//
//  Created by Kyu Hyun Chang on 6/15/16.
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


#import <Foundation/Foundation.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>
#import "LeanplumHelper.h"
#import <Leanplum/LPConstants.h>
#import <Leanplum/LPJSON.h>
#import <Leanplum/LPActionTriggerManager.h>
#import <Leanplum/LPVarCache.h>
#import <Leanplum/Leanplum.h>
#import <Leanplum/Leanplum-Swift.h>
#import <Leanplum/LeanplumInternal.h>
#import "LPRequestSender+Categories.h"
#import "LPNetworkEngine+Category.h"
#import <Leanplum/Leanplum-Swift.h>

@interface MessagesTest : XCTestCase

@property (nonatomic) LeanplumMessageMatchResult mockResult;
@property (nonatomic) id mockActionManager;
@property (nonatomic) id mockLPInternalState;
@property (nonatomic) NSArray *mockWhenCondtions;
@property (nonatomic) NSString *mockEventName;
@property (nonatomic) LeanplumActionFilter mockFilter;
@property (nonatomic) NSString *mockFromMessageId;
@property (nonatomic) LPContextualValues *mockContextualValues;

@end

@interface LPActionTriggerManagerMock: LPActionTriggerManager

@property (nonatomic, strong, nullable) void (^actionsMatched)(NSArray<LPActionContext *> *context);

@end

@implementation LPActionTriggerManagerMock

- (NSMutableArray<LPActionContext *> *)matchActions:(NSDictionary *)actions withTrigger:(ActionsTrigger *)trigger withFilter:(LeanplumActionFilter)filter fromMessageId:(NSString *)sourceMessage
{
    NSMutableArray *contexts = [super matchActions:actions withTrigger:trigger withFilter:filter fromMessageId:sourceMessage];
    
    if (self.actionsMatched) {
        self.actionsMatched(contexts);
    }
    return contexts;
}

@end

@interface LPLocalNotificationsManagerMock: LPLocalNotificationsManager

@property (nonatomic, strong, nullable) void (^notificationScheduled)(LPActionContext *context);

@end

@implementation LPLocalNotificationsManagerMock

- (void)scheduleLocalNotification:(LPActionContext *)context {
    if (self.notificationScheduled) {
        self.notificationScheduled(context);
    }
}

@end

@implementation MessagesTest

- (void)setUp
{
    [super setUp];
    // Automatically sets up AppId and AccessKey for development mode.
    [LeanplumHelper setup_development_test];
    [self setMockResult];
    [self setMockActionManager];
    [self setMockLPInternalState];
    [self setParametersForMaybePerformAction];
}

- (void)tearDown
{
    [super tearDown];
    [LeanplumHelper clean_up];
    [self.mockActionManager stopMocking];
    [self.mockLPInternalState stopMocking];
}

- (void)setMockResult
{
    self.mockResult = LeanplumMessageMatchResultMake(YES, NO, YES, YES);
    XCTAssertFalse(self.mockResult.matchedUnlessTrigger);
    XCTAssertTrue(self.mockResult.matchedTrigger);
    XCTAssertTrue(self.mockResult.matchedLimit);
    XCTAssertTrue(self.mockResult.matchedActivePeriod);
}

- (void)setMockResultActivePeriodFalse
{
    self.mockResult = LeanplumMessageMatchResultMake(YES, NO, YES, NO);
    XCTAssertFalse(self.mockResult.matchedUnlessTrigger);
    XCTAssertTrue(self.mockResult.matchedTrigger);
    XCTAssertTrue(self.mockResult.matchedLimit);
    XCTAssertFalse(self.mockResult.matchedActivePeriod);
}

- (void)setMockActionManager
{
    self.mockActionManager = OCMClassMock([LPActionTriggerManager class]);
    OCMStub([self.mockActionManager shouldShowMessage:[OCMArg any]
                                      withConfig:[OCMArg any]
                                            when:[OCMArg any]
                                   withEventName:[OCMArg any]
                                contextualValues:[OCMArg any]]).andReturn(self.mockResult);

    LeanplumMessageMatchResult testResult =
        [self.mockActionManager shouldShowMessage:@"test"
                                       withConfig:[NSDictionary dictionary]
                                             when:@"test"
                                    withEventName:@"test"
                                 contextualValues:[[LPContextualValues alloc]init]];

    XCTAssertTrue(testResult.matchedTrigger);
    XCTAssertTrue(testResult.matchedLimit);
}

- (void)setMockLPInternalState
{
    LPInternalState *lp = [[LPInternalState alloc] init];
    lp.actionManager = self.mockActionManager;
    self.mockLPInternalState = OCMClassMock([LPInternalState class]);
    OCMStub([self.mockLPInternalState sharedState]).andReturn(lp);
}

- (void)setParametersForMaybePerformAction
{
    self.mockWhenCondtions = @[@"Event"];
    self.mockEventName = @"TestActivity";
    self.mockFilter = kLeanplumActionFilterAll;
    self.mockFromMessageId = nil;
    self.mockContextualValues = [[LPContextualValues alloc] init];
}

- (void)runInAppMessagePrioritizationTest:(NSDictionary *)messageConfigs
                   withExpectedMessageIds:(NSSet *)expectedMessageIds
{
    [[ActionManager shared] setMessages:messageConfigs];
    XCTestExpectation *expectation = [self expectationWithDescription:@"wait_for_match_action_contexts"];
    LPActionTriggerManagerMock *mock = [LPActionTriggerManagerMock new];
    [mock setActionsMatched:^(NSArray<LPActionContext *> *contexts) {
        
        __block NSMutableSet *calledMessageIds = [NSMutableSet set];
//        [contexts enumerateObjectsUsingBlock:^(LPActionContext * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
//            [calledMessageIds addObject:obj.messageId];
//        }];
        if (contexts.count > 0) {
            [calledMessageIds addObject:contexts[0].messageId];
        }
        XCTAssertTrue([calledMessageIds isEqualToSet:expectedMessageIds]);
        [expectation fulfill];
    }];
    
    ActionsTrigger *trigger = [[ActionsTrigger alloc] initWithEventName:self.mockEventName
                                                              condition:self.mockWhenCondtions
                                                       contextualValues:self.mockContextualValues];
    
    [mock matchActions:messageConfigs
           withTrigger:trigger
            withFilter:self.mockFilter
         fromMessageId:self.mockFromMessageId];

    [self waitForExpectations:@[expectation] timeout:5.0];
}

- (void) test_single_message
{
    NSString *jsonString = [LeanplumHelper retrieve_string_from_file:@"SingleMessage"
                                                              ofType:@"json"];

    NSDictionary *messageConfigs = [LPJSON JSONFromString:jsonString];
    [self runInAppMessagePrioritizationTest:messageConfigs
                     withExpectedMessageIds:[NSSet setWithObjects: @"1", nil]];

    // Test creating action context for message id.
    LPActionContext *context = [Leanplum createActionContextForMessageId:@"1"];
    XCTAssertEqualObjects(@"Alert", context.actionName);
}

- (void) test_no_priorities
{
    // Testing three messages with no priority values.
    NSString *jsonString = [LeanplumHelper retrieve_string_from_file:@"NoPriorities"
                                                              ofType:@"json"];

    NSDictionary *messageConfigs = [LPJSON JSONFromString:jsonString];
    [self runInAppMessagePrioritizationTest:messageConfigs
                     withExpectedMessageIds:[NSSet setWithObjects:@"1", nil]];
}

- (void) test_different_priorities_small
{
    // Testing three messages with priorities of 1, 2, and 3.
    NSString *jsonString = [LeanplumHelper retrieve_string_from_file:@"DifferentPriorities1"
                                                              ofType:@"json"];

    NSDictionary *messageConfigs = [LPJSON JSONFromString:jsonString];
    [self runInAppMessagePrioritizationTest:messageConfigs
                     withExpectedMessageIds:[NSSet setWithObjects:@"1", nil]];
}

- (void) test_different_priorities_large
{
    // Testing three messages with priorities of 10, 1000, and 5.
    NSString *jsonString = [LeanplumHelper retrieve_string_from_file:@"DifferentPriorities2"
                                                    ofType:@"json"];
    NSDictionary *messageConfigs = [LPJSON JSONFromString:jsonString];
    [self runInAppMessagePrioritizationTest:messageConfigs
                     withExpectedMessageIds:[NSSet setWithObjects:@"3", nil]];
}

- (void) test_tied_priorities_no_value
{
    // Testing three messages with priorities of 5, no value, and 5.
    NSString *jsonString = [LeanplumHelper retrieve_string_from_file:@"TiedPriorities1"
                                                              ofType:@"json"];

    NSDictionary *messageConfigs = [LPJSON JSONFromString:jsonString];
    [self runInAppMessagePrioritizationTest:messageConfigs
                     withExpectedMessageIds:[NSSet setWithObjects:@"1", nil]];
}

- (void) test_tied_priorities_identical
{
    // Testing three messages with the same priority.
    NSString *jsonString = [LeanplumHelper retrieve_string_from_file:@"TiedPriorities2"
                                                    ofType:@"json"];
    NSDictionary *messageConfigs = [LPJSON JSONFromString:jsonString];
    [self runInAppMessagePrioritizationTest:messageConfigs
                     withExpectedMessageIds:[NSSet setWithObjects:@"1", nil]];
}

- (void) test_tied_priorities_identical_different_countdown
{
    // Testing three messages with the same priority.
    NSString *jsonString = [LeanplumHelper retrieve_string_from_file:@"TiedPrioritiesDifferentDelay"
                                                              ofType:@"json"];
    NSDictionary *messageConfigs = [LPJSON JSONFromString:jsonString];
    [[ActionManager shared] setMessages:messageConfigs];
    id mockLPLocalNotificationsManager = OCMClassMock([LPLocalNotificationsManager class]);
    // Countdown is valid only for local notifications.
    XCTestExpectation *expectation = [self expectationWithDescription:@"wait_for_local_notification_schedule"];
    LPLocalNotificationsManagerMock *mockManager = [LPLocalNotificationsManagerMock new];
    
    __block NSMutableSet *scheduled = [NSMutableSet set];
    [mockManager setNotificationScheduled:^(LPActionContext *context) {
        [scheduled addObject:context.messageId];
        if ([scheduled isEqualToSet:[NSSet setWithObjects:@"1", @"2", @"3", nil]]) {
            [expectation fulfill];
        }
    }];
    
    OCMStub(ClassMethod([mockLPLocalNotificationsManager sharedManager])).andReturn(mockManager);
    
    [Leanplum maybePerformActions:self.mockWhenCondtions withEventName:self.mockEventName withFilter:self.mockFilter fromMessageId:self.mockFromMessageId withContextualValues:self.mockContextualValues];
    
    [self waitForExpectations:@[expectation] timeout:5.0];
    [mockLPLocalNotificationsManager stopMocking];
}

- (void) test_tied_priorities_identical_countdown
{
    // Testing three messages with the same priority.
    NSString *jsonString = [LeanplumHelper retrieve_string_from_file:@"TiedPrioritiesDelay"
                                                              ofType:@"json"];
    NSDictionary *messageConfigs = [LPJSON JSONFromString:jsonString];
    
    [[ActionManager shared] setMessages:messageConfigs];
    id mockLPLocalNotificationsManager = OCMClassMock([LPLocalNotificationsManager class]);
    // Countdown is valid only for local notifications.
    XCTestExpectation *expectation = [self expectationWithDescription:@"wait_for_local_notification_schedule"];
    LPLocalNotificationsManagerMock *mockManager = [LPLocalNotificationsManagerMock new];
    
    __block NSMutableSet *scheduled = [NSMutableSet set];
    [mockManager setNotificationScheduled:^(LPActionContext *context) {
        [scheduled addObject:context.messageId];
        // "1" and "3" have the same priority and countdown, only one of them will be added
        // which one is undetermined since actions are ordered by priority only
        if ([scheduled containsObject:@"2"]
            && ([scheduled containsObject:@"3"] || [scheduled containsObject:@"1"])) {
            [expectation fulfill];
        }
    }];
    
    OCMStub(ClassMethod([mockLPLocalNotificationsManager sharedManager])).andReturn(mockManager);
    
    [Leanplum maybePerformActions:self.mockWhenCondtions withEventName:self.mockEventName withFilter:self.mockFilter fromMessageId:self.mockFromMessageId withContextualValues:self.mockContextualValues];
    
    [self waitForExpectations:@[expectation] timeout:5.0];
    [mockLPLocalNotificationsManager stopMocking];
}

- (void) test_different_priorities_with_missing_values
{
    // Testing  three messages with priorities of 10, 30, and no value.
    NSString *jsonString = [LeanplumHelper
                            retrieve_string_from_file:@"DifferentPrioritiesWithMissingValues"
                                               ofType:@"json"];

    NSDictionary *messageConfigs = [LPJSON JSONFromString:jsonString];
    [self runInAppMessagePrioritizationTest:messageConfigs
                     withExpectedMessageIds:[NSSet setWithObjects:@"1", nil]];
}

- (void)test_chained_messages
{
    NSString *jsonString = [LeanplumHelper
                            retrieve_string_from_file:@"ChainedMessage"
                            ofType:@"json"];
    NSDictionary *messageConfigs = [LPJSON JSONFromString:jsonString];
    [[ActionManager shared] setMessages:messageConfigs];

    LPActionContext *context1 = [Leanplum createActionContextForMessageId:@"1"];
    LPActionContext *context2 = [Leanplum createActionContextForMessageId:@"2"];

    // Capture Creating New Action.
    NSString __block *chainedMessageId = nil;
    id mockLeanplum = OCMClassMock([Leanplum class]);
    OCMStub([mockLeanplum createActionContextForMessageId:[OCMArg any]])
    .andDo(^(NSInvocation *invocation){
        // __unsafe_unretained prevents double-release.
        __unsafe_unretained NSString *messageId;
        [invocation getArgument:&messageId atIndex:2];

        chainedMessageId = messageId;
    }).andReturn(context1);

    // Run Dismiss Action on 2 that will chain to 1.
    [context2 runActionNamed:@"Dismiss action"];
    XCTAssertTrue([chainedMessageId isEqual:@"1"]);
    
    [mockLeanplum stopMocking];
}

- (void) test_active_period_true
{
    NSString *jsonString = [LeanplumHelper retrieve_string_from_file:@"SingleMessage"
                                                              ofType:@"json"];
    
    NSDictionary *messageConfigs = [LPJSON JSONFromString:jsonString];
    [self runInAppMessagePrioritizationTest:messageConfigs
                     withExpectedMessageIds:[NSSet setWithObjects: @"1", nil]];
    
    // Test creating action context for message id.
    LPActionContext *context = [Leanplum createActionContextForMessageId:@"1"];
    XCTAssertEqualObjects(@"Alert", context.actionName);
}

- (void) test_active_period_false
{
    [self setMockResultActivePeriodFalse];
    [self setMockActionManager];
    [self setMockLPInternalState];
    
    NSString *jsonString = [LeanplumHelper retrieve_string_from_file:@"SingleMessage"
                                                              ofType:@"json"];
    
    NSDictionary *messageConfigs = [LPJSON JSONFromString:jsonString];
    [self runInAppMessagePrioritizationTest:messageConfigs
                     withExpectedMessageIds:[NSSet set]];
    
}

@end
