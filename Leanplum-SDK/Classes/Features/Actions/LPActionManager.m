//
//  LPActionManager.m
//  Leanplum
//
//  Created by Andrew First on 9/12/13.
//  Copyright (c) 2013 Leanplum, Inc. All rights reserved.
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

#import "LPActionManager.h"

#import "LPConstants.h"
#import "LPSwizzle.h"
#import "LeanplumInternal.h"
#import "LPFileManager.h"
#import "LPVarCache.h"
#import "LPUIAlert.h"
#import "LPMessageTemplates.h"
#import "LPRequestFactory.h"
#import "LPRequestSender.h"
#import "LPAPIConfig.h"
#import "LPCountAggregator.h"

#import <objc/runtime.h>
#import <objc/message.h>

LeanplumMessageMatchResult LeanplumMessageMatchResultMake(BOOL matchedTrigger, BOOL matchedUnlessTrigger, BOOL matchedLimit, BOOL matchedActivePeriod)
{
    LeanplumMessageMatchResult result;
    result.matchedTrigger = matchedTrigger;
    result.matchedUnlessTrigger = matchedUnlessTrigger;
    result.matchedLimit = matchedLimit;
    result.matchedActivePeriod = matchedActivePeriod;
    return result;
}

@interface LPActionManager()

@property (nonatomic, strong) NSMutableDictionary *messageImpressionOccurrences;
@property (nonatomic, strong) NSMutableDictionary *messageTriggerOccurrences;
@property (nonatomic, strong) NSMutableDictionary *sessionOccurrences;
@property (nonatomic, strong) NSString *displayedTracked;
@property (nonatomic, strong) NSDate *displayedTrackedTime;
@property (nonatomic, strong) LPCountAggregator *countAggregator;

@end

@implementation LPActionManager

static LPActionManager *leanplum_sharedActionManager = nil;
static dispatch_once_t leanplum_onceToken;

+ (LPActionManager *)sharedManager
{
    dispatch_once(&leanplum_onceToken, ^{
        leanplum_sharedActionManager = [[self alloc] init];
    });
    return leanplum_sharedActionManager;
}

// Used for unit testing.
+ (void)reset
{
    leanplum_sharedActionManager = nil;
    leanplum_onceToken = 0;
}

- (id)init
{
    if (self = [super init]) {
        [[LPLocalNotificationsManager sharedManager] listenForLocalNotifications];
        _sessionOccurrences = [NSMutableDictionary dictionary];
        _messageImpressionOccurrences = [NSMutableDictionary dictionary];
        _messageTriggerOccurrences = [NSMutableDictionary dictionary];
        _countAggregator = [LPCountAggregator sharedAggregator];
    }
    return self;
}

- (BOOL)hasTrackedDisplayed:(NSDictionary *)userInfo
{
    if ([self.displayedTracked isEqualToString:[LPJSON stringFromJSON:userInfo]] &&
        [[NSDate date] timeIntervalSinceDate:self.displayedTrackedTime] < 10.0) {
        return YES;
    }

    self.displayedTracked = [LPJSON stringFromJSON:userInfo];
    self.displayedTrackedTime = [NSDate date];
    return NO;
}

#pragma mark - Delivery

- (NSMutableDictionary *)getMessageImpressionOccurrences:(NSString *)messageId
{
    NSMutableDictionary *occurrences = _messageImpressionOccurrences[messageId];
    if (occurrences) {
        return occurrences;
    }
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *savedValue = [defaults objectForKey:
                                [NSString stringWithFormat:LEANPLUM_DEFAULTS_MESSAGE_IMPRESSION_OCCURRENCES_KEY, messageId]];
    if (savedValue) {
        occurrences = [savedValue mutableCopy];
        _messageImpressionOccurrences[messageId] = occurrences;
    }
    return occurrences;
}

// Increment message impression occurrences.
// The @synchronized insures multiple threads create and increment the same
// dictionary. A corrupt dictionary will cause an NSUserDefaults crash.
- (void)incrementMessageImpressionOccurrences:(NSString *)messageId
{
    @synchronized (_messageImpressionOccurrences) {
        NSMutableDictionary *occurrences = [self getMessageImpressionOccurrences:messageId];
        if (occurrences == nil) {
            occurrences = [NSMutableDictionary dictionary];
            occurrences[@"min"] = @(0);
            occurrences[@"max"] = @(0);
            occurrences[@"0"] = @([[NSDate date] timeIntervalSince1970]);
        } else {
            int min = [occurrences[@"min"] intValue];
            int max = [occurrences[@"max"] intValue];
            max++;
            occurrences[[NSString stringWithFormat:@"%d", max]] =
                    @([[NSDate date] timeIntervalSince1970]);
            if (max - min + 1 > MAX_STORED_OCCURRENCES_PER_MESSAGE) {
                [occurrences removeObjectForKey:[NSString stringWithFormat:@"%d", min]];
                min++;
                occurrences[@"min"] = @(min);
            }
            occurrences[@"max"] = @(max);
        }
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:occurrences
                     forKey:[NSString stringWithFormat:LEANPLUM_DEFAULTS_MESSAGE_IMPRESSION_OCCURRENCES_KEY, messageId]];
    }
}

- (NSInteger)getMessageTriggerOccurrences:(NSString *)messageId
{
    NSNumber *occurrences = _messageTriggerOccurrences[messageId];
    if (occurrences) {
        return [occurrences intValue];
    }
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSInteger savedValue = [defaults integerForKey:
                            [NSString stringWithFormat:LEANPLUM_DEFAULTS_MESSAGE_TRIGGER_OCCURRENCES_KEY, messageId]];
    _messageTriggerOccurrences[messageId] = @(savedValue);
    return savedValue;
}

- (void)incrementMessageTriggerOccurrences:(NSString *)messageId
{
    @synchronized (_messageTriggerOccurrences) {
        NSInteger occurrences = [self getMessageTriggerOccurrences:messageId];
        occurrences++;
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setInteger:occurrences
                      forKey:[NSString stringWithFormat:LEANPLUM_DEFAULTS_MESSAGE_TRIGGER_OCCURRENCES_KEY, messageId]];
        _messageTriggerOccurrences[messageId] = @(occurrences);
    }   
}

+ (BOOL)matchedTriggers:(NSDictionary *)triggerConfig
                   when:(NSString *)when
              eventName:(NSString *)eventName
       contextualValues:(LPContextualValues *)contextualValues
{
    if ([triggerConfig isKindOfClass:[NSDictionary class]]) {
        NSArray *triggers = triggerConfig[@"children"];
        for (NSDictionary *trigger in triggers) {
            if ([self matchedTrigger:trigger
                                when:when
                           eventName:eventName
                    contextualValues:contextualValues]) {
                return YES;
            }
        }
    }
    return NO;
}

+ (BOOL)matchedTrigger:(NSDictionary *)trigger
                  when:(NSString *)when
             eventName:(NSString *)eventName
      contextualValues:(LPContextualValues *)contextualValues
{
    NSString *subject = trigger[@"subject"];
    if ([subject isEqualToString:when]) {
        NSString *noun = trigger[@"noun"];
        if ((noun == nil && eventName == nil) || [noun isEqualToString:eventName]) {
            NSString *verb = trigger [@"verb"];
            NSArray *objects = trigger[@"objects"];

            // Evaluate user attribute changed to value.
            if ([verb isEqual:@"changesTo"]) {
                NSString *value = [contextualValues.attributeValue description];
                for (id object in objects) {
                    if ([[object description]
                         caseInsensitiveCompare:value] == NSOrderedSame) {
                        return YES;
                    }
                }
                return NO;
            }

            // Evaluate user attribute changed from value to value.
            if ([verb isEqual:@"changesFromTo"]) {
                NSString *previousValue = [[contextualValues previousAttributeValue] description];
                NSString *value = [contextualValues.attributeValue description];
                return objects.count >= 2 &&
                    [[objects[0] description]
                        caseInsensitiveCompare:previousValue] == NSOrderedSame &&
                    [[objects[1] description] caseInsensitiveCompare:value] == NSOrderedSame;
            }

            // Evaluate event parameter is value.
            if ([verb isEqual:@"triggersWithParameter"]) {
                // We need to check whether the key is in the parameter
                // or else it will create a null object that will always return YES.
                return objects.count >= 2 &&
                    contextualValues.parameters[objects[0]] &&
                    [[contextualValues.parameters[objects[0]] description]
                        caseInsensitiveCompare:[objects[1] description]] == NSOrderedSame;
            }

            return YES;
        }
    }
    return NO;
}

+ (void)getForegroundRegionNames:(NSMutableSet **)foregroundRegionNames
        andBackgroundRegionNames:(NSMutableSet **)backgroundRegionNames
{
    *foregroundRegionNames = [NSMutableSet set];
    *backgroundRegionNames = [NSMutableSet set];
    NSDictionary *messages = [[LPVarCache sharedCache] messages];
    for (NSString *messageId in messages) {
        NSDictionary *messageConfig = messages[messageId];
        NSMutableSet *regionNames;
        id action = messageConfig[@"action"];
        if ([action isKindOfClass:NSString.class]) {
            if ([action isEqualToString:LP_PUSH_NOTIFICATION_ACTION]) {
                regionNames = *backgroundRegionNames;
            } else {
                regionNames = *foregroundRegionNames;
            }
            [LPActionManager addRegionNamesFromTriggers:messageConfig[@"whenTriggers"]
                                                  toSet:regionNames];
            [LPActionManager addRegionNamesFromTriggers:messageConfig[@"unlessTriggers"]
                                                  toSet:regionNames];
        }
    }
}

+ (void)addRegionNamesFromTriggers:(NSDictionary *)triggerConfig toSet:(NSMutableSet *)set
{
    NSArray *triggers = triggerConfig[@"children"];
    for (NSDictionary *trigger in triggers) {
        NSString *subject = trigger[@"subject"];
        if ([subject isEqualToString:@"enterRegion"] ||
            [subject isEqualToString:@"exitRegion"]) {
            [set addObject:trigger[@"noun"]];
        }
    }
}

- (LeanplumMessageMatchResult)shouldShowMessage:(NSString *)messageId
                                     withConfig:(NSDictionary *)messageConfig
                                           when:(NSString *)when
                                  withEventName:(NSString *)eventName
                               contextualValues:(LPContextualValues *)contextualValues
{
    LeanplumMessageMatchResult result = LeanplumMessageMatchResultMake(NO, NO, NO, NO);

    // 1. Must not be muted.
    if ([[NSUserDefaults standardUserDefaults] boolForKey:
         [NSString stringWithFormat:LEANPLUM_DEFAULTS_MESSAGE_MUTED_KEY, messageId]]) {
        return result;
    }

    // 2. Must match at least one trigger.
    result.matchedTrigger = [LPActionManager matchedTriggers:messageConfig[@"whenTriggers"]
                                                        when:when
                                                   eventName:eventName
                                            contextualValues:contextualValues];
    result.matchedUnlessTrigger = [LPActionManager matchedTriggers:messageConfig[@"unlessTriggers"]
                                                              when:when
                                                         eventName:eventName
                                                  contextualValues:contextualValues];
    if (!result.matchedTrigger && !result.matchedUnlessTrigger) {
        return result;
    }

    // 3. Must match all limit conditions.
    NSDictionary *limitConfig = messageConfig[@"whenLimits"];
    result.matchedLimit = [self matchesLimits:limitConfig messageId:messageId];

    // 4. Must be within active period.
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    NSTimeInterval startTime = [messageConfig[@"startTime"] doubleValue] / 1000.0;
    NSTimeInterval endTime = [messageConfig[@"endTime"] doubleValue] / 1000.0;
    if (startTime && endTime) {
        result.matchedActivePeriod = now > startTime && now < endTime;
    } else {
        result.matchedActivePeriod = YES;
    }
    
    return result;
}

- (BOOL)matchesLimits:(NSDictionary *)limitConfig
            messageId:(NSString *)messageId
{
    if (![limitConfig isKindOfClass:[NSDictionary class]]) {
        return YES;
    }
    NSArray *limits = limitConfig[@"children"];
    if (!limits.count) {
        return YES;
    }
    NSDictionary *impressionOccurrences = [self getMessageImpressionOccurrences:messageId];
    NSInteger triggerOccurrences = [self getMessageTriggerOccurrences:messageId] + 1;
    for (NSDictionary *limit in limits) {
        NSString *subject = limit[@"subject"];
        NSString *noun = limit[@"noun"];
        NSString *verb = limit[@"verb"];

        // E.g. 5 times per session; 2 times per 7 minutes.
        if ([subject isEqualToString:@"times"]) {
            if (![self matchesLimitTimes:[noun intValue]
                                     per:[[limit[@"objects"] firstObject] intValue]
                               withUnits:verb
                             occurrences:impressionOccurrences
                               messageId:messageId]) {
                return NO;
            }
        
        // E.g. On the 5th occurrence.
        } else if ([subject isEqualToString:@"onNthOccurrence"]) {
            int amount = [noun intValue];
            if (triggerOccurrences != amount) {
                return NO;
            }

        // E.g. Every 5th occurrence.
        } else if ([subject isEqualToString:@"everyNthOccurrence"]) {
            int multiple = [noun intValue];
            if (multiple == 0 || triggerOccurrences % multiple != 0) {
                return NO;
            }
        }
    }
    return YES;
}

- (BOOL)matchesLimitTimes:(int)amount
                      per:(int)time
                withUnits:(NSString *)units
              occurrences:(NSDictionary *)occurrences
                messageId:(NSString *)messageId
{
    int existing = 0;
    if ([units isEqualToString:@"limitSession"]) {
        existing = [_sessionOccurrences[messageId] intValue];
    } else {
        if (occurrences == nil) {
            return YES;
        }
        int min = [occurrences[@"min"] intValue];
        int max = [occurrences[@"max"] intValue];
        if ([units isEqualToString:@"limitUser"]) {
            existing = max - min + 1;
        } else {
            int perSeconds = time;
            if ([units isEqualToString:@"limitMinute"]) {
                perSeconds *= 60;
            } else if ([units isEqualToString:@"limitHour"]) {
                perSeconds *= 3600;
            } else if ([units isEqualToString:@"limitDay"]) {
                perSeconds *= 86400;
            } else if ([units isEqualToString:@"limitWeek"]) {
                perSeconds *= 604800;
            } else if ([units isEqualToString:@"limitMonth"]) {
                perSeconds *= 2592000;
            }
            NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
            int matchedOccurrences = 0;
            for (int i = max; i >= min; i--) {
                NSTimeInterval timeAgo = now -
                        [occurrences[[NSString stringWithFormat:@"%d", i]] doubleValue];
                if (timeAgo > perSeconds) {
                    break;
                }
                matchedOccurrences++;
                if (matchedOccurrences >= amount) {
                    return NO;
                }
            }
        }
    }
    return existing < amount;
}

- (void)recordMessageTrigger:(NSString *)messageId
{
    [self incrementMessageTriggerOccurrences:messageId];
    
    [self.countAggregator incrementCount:@"record_message_trigger"];
}

/**
 * Tracks the "Open" event for a message and records it's occurrence.
 * @param messageId The ID of the message
 */
- (void)recordMessageImpression:(NSString *)messageId
{
    [self recordImpression:messageId originalMessageId:nil];
}

/**
 * Tracks the "Held Back" event for a message and records the held back occurrences.
 * @param messageId The spoofed ID of the message.
 * @param originalMessageId The original ID of the held back message.
 */
- (void)recordHeldBackImpression:(NSString *)messageId
               originalMessageId:(NSString *)originalMessageId
{
    [self recordImpression:messageId originalMessageId:originalMessageId];
}

/**
 * Records the occurrence of a message and tracks the correct impression event.
 * @param messageId The ID of the message.
 * @param originalMessageId The original message ID of the held back message. Supply this
 *     only if the message is held back. Otherwise, use nil.
 */
- (void)recordImpression:(NSString *)messageId originalMessageId:(NSString *)originalMessageId
{
    if (originalMessageId) {
        // This is a held back impression - track it with the original message id.
        [Leanplum track:LP_HELD_BACK_EVENT_NAME withValue:0.0 andInfo:nil
                andArgs:@{LP_PARAM_MESSAGE_ID: originalMessageId} andParameters:nil];
    } else {
        // Track occurrence.
        [Leanplum track:nil withValue:0.0 andInfo:nil
                andArgs:@{LP_PARAM_MESSAGE_ID: messageId} andParameters:nil];
    }

    // Record session occurrences.
    @synchronized (_sessionOccurrences) {
        int existing = [_sessionOccurrences[messageId] intValue];
        existing++;
        _sessionOccurrences[messageId] = @(existing);
    }
    
    // Record cross-session occurrences.
    [self incrementMessageImpressionOccurrences:messageId];
}

- (void)muteFutureMessagesOfKind:(NSString *)messageId
{
    if (messageId) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setBool:YES forKey:[NSString stringWithFormat:LEANPLUM_DEFAULTS_MESSAGE_MUTED_KEY, messageId]];
    }
}

@end
