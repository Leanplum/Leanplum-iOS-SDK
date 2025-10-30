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

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "LPInbox.h"

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(ActionArg)
@interface LPActionArg : NSObject

- (instancetype)init NS_UNAVAILABLE;

/**
 * @{
 * Defines a Leanplum Action Argument
 */
+ (LPActionArg *)argNamed:(NSString *)name
               withNumber:(NSNumber *)defaultValue
NS_SWIFT_NAME(init(name:number:));

+ (LPActionArg *)argNamed:(NSString *)name
               withString:(NSString *)defaultValue
NS_SWIFT_NAME(init(name:string:));

+ (LPActionArg *)argNamed:(NSString *)name
                 withBool:(BOOL)defaultValue
NS_SWIFT_NAME(init(name:boolean:));

+ (LPActionArg *)argNamed:(NSString *)name
                 withFile:(nullable NSString *)defaultValue
NS_SWIFT_NAME(init(name:file:));

+ (LPActionArg *)argNamed:(NSString *)name
                 withDict:(NSDictionary *)defaultValue
NS_SWIFT_NAME(init(name:dictionary:));

+ (LPActionArg *)argNamed:(NSString *)name
                withArray:(NSArray *)defaultValue
NS_SWIFT_NAME(init(name:array:));

+ (LPActionArg *)argNamed:(NSString *)name
               withAction:(nullable NSString *)defaultValue
NS_SWIFT_NAME(init(name:action:));

+ (LPActionArg *)argNamed:(NSString *)name
                withColor:(UIColor *)defaultValue
NS_SWIFT_NAME(init(name:color:));
/**@}*/

@property (readonly, strong) NSString *name;
@property (readonly, strong) id defaultValue;
@property (readonly, strong) NSString *kind;

@end

NS_ASSUME_NONNULL_END
