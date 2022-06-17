//
//  LPActionTriggerManager.h
//  Leanplum
//
//  Created by Andrew First on 9/12/13.
//  Copyright (c) 2022 Leanplum, Inc. All rights reserved.
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

#import "Leanplum.h"

#import <Foundation/Foundation.h>
#import "LPContextualValues.h"
#import <UserNotifications/UserNotifications.h>
#import "LPLocalNotificationsManager.h"

@class ActionsTrigger;

NS_ASSUME_NONNULL_BEGIN

struct LeanplumMessageMatchResult {
    BOOL matchedTrigger;
    BOOL matchedUnlessTrigger;
    BOOL matchedLimit;
    BOOL matchedActivePeriod;
};
typedef struct LeanplumMessageMatchResult LeanplumMessageMatchResult;

LeanplumMessageMatchResult LeanplumMessageMatchResultMake(BOOL matchedTrigger, BOOL matchedUnlessTrigger, BOOL matchedLimit, BOOL matchedActivePeriod);

typedef NS_OPTIONS(NSUInteger, LeanplumActionFilter) {
    kLeanplumActionFilterForeground = 0b1,
    kLeanplumActionFilterBackground = 0b10,
    kLeanplumActionFilterAll = 0b11
} NS_SWIFT_NAME(Leanplum.ActionFilter);

#define LP_HELD_BACK_ACTION @"__held_back"

@interface LPActionTriggerManager : NSObject {
    
}

+ (LPActionTriggerManager*) sharedManager
NS_SWIFT_NAME(shared());

+ (void)getForegroundRegionNames:(NSMutableSet * _Nonnull * _Nullable)foregroundRegionNames
        andBackgroundRegionNames:(NSMutableSet * _Nonnull * _Nullable)backgroundRegionNames;

#pragma mark - Messages

- (LeanplumMessageMatchResult)shouldShowMessage:(NSString *)messageId
                                     withConfig:(NSDictionary *)messageConfig
                                           when:(NSString *)when
                                  withEventName:(NSString *)eventName
                               contextualValues:(LPContextualValues *)contextualValues;

- (NSMutableArray<LPActionContext *> *)matchActions:(NSDictionary *)actions
                                        withTrigger:(ActionsTrigger *)trigger
                                         withFilter:(LeanplumActionFilter)filter
                                      fromMessageId:(NSString *)sourceMessage;

- (void)recordMessageTrigger:(NSString *)messageId;
- (void)recordMessageImpression:(NSString *)messageId;
- (void)recordHeldBackImpression:(NSString *)messageId
               originalMessageId:(NSString *)originalMessageId;
- (void)recordChainedActionImpression:(NSString *)messageId;
- (void)recordLocalPushImpression:(NSString *)messageId;

- (BOOL)shouldSuppressMessages;

#pragma mark - Leanplum Tests

+ (void)reset;

@end

NS_ASSUME_NONNULL_END
