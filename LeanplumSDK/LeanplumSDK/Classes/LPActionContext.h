//
//  Leanplum.h
//  Leanplum iOS SDK Version 2.0.6
//
//  Copyright (c) 2012 Leanplum, Inc. All rights reserved.
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

#import <UIKit/UIKit.h>
#import "Leanplum.h"

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(ActionContext)
@interface LPActionContext : NSObject

- (instancetype)init NS_UNAVAILABLE;

/**
 * The id of the message in the context if present
 */
@property (readonly, strong) NSString *messageId;

/**
 * Copy of the Context arguments
 */
@property (readonly, strong, nullable) NSDictionary *args;

/**
 * The parent ActionContext if present
 */
@property (readonly, nonatomic, strong, nullable) LPActionContext *parentContext;

/// Bool indicating if the message is a chained message
@property (readonly) BOOL isChainedMessage;

- (id)objectNamed:(NSString *)name
NS_SWIFT_NAME(object(name:));

- (NSString *)actionName
NS_SWIFT_NAME(action());

- (nullable NSString *)stringNamed:(NSString *)name
NS_SWIFT_NAME(string(name:));

- (nullable NSString *)fileNamed:(NSString *)name
NS_SWIFT_NAME(file(name:));

- (nullable NSNumber *)numberNamed:(NSString *)name
NS_SWIFT_NAME(number(name:));

- (BOOL)boolNamed:(NSString *)name
NS_SWIFT_NAME(boolean(name:));

- (nullable NSDictionary *)dictionaryNamed:(NSString *)name
NS_SWIFT_NAME(dictionary(name:));

- (nullable NSArray *)arrayNamed:(NSString *)name
NS_SWIFT_NAME(array(name:));

- (nullable UIColor *)colorNamed:(NSString *)name
NS_SWIFT_NAME(color(name:));

- (nullable NSURL *)htmlWithTemplateNamed:(NSString *)templateName
NS_SWIFT_NAME(htmlTemplate(name:));

/**
 * Runs the action given by the "name" key.
 */
- (void)runActionNamed:(NSString *)name
NS_SWIFT_NAME(runAction(name:));

/**
 * Runs and tracks an event for the action given by the "name" key.
 * This will track an event if no action is set.
 */
- (void)runTrackedActionNamed:(NSString *)name
NS_SWIFT_NAME(runTrackedAction(name:));

/**
 * Tracks an event in the context of the current message.
 */
- (void)track:(NSString *)event
    withValue:(double)value
andParameters:(nullable NSDictionary<NSString *, id> *)params
NS_SWIFT_NAME(track(event:value:params:));

/**
 * Tracks an event in the conext of the current message, with any parent actions prepended to the
 * message event name.
 */
- (void)trackMessageEvent:(NSString *)event
                withValue:(double)value
                  andInfo:(nullable NSString *)info
            andParameters:(nullable NSDictionary<NSString *, id> *)params
NS_SWIFT_NAME(trackMessage(event:value:info:params:));

/**
 * Checks if the action context has any missing files that still need to be downloaded.
 */
- (BOOL)hasMissingFiles;

/// Needs to be called when action was dismissed
- (void)actionDismissed;

@end

NS_ASSUME_NONNULL_END
