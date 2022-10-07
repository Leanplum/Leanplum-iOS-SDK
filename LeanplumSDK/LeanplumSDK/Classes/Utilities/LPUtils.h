//
//  LPUtils.h
//  Leanplum
//
//  Created by Ben Marten on 6/6/16.
//  Copyright (c) 2016 Leanplum, Inc. All rights reserved.
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

@interface LPUtils : NSObject

/**
 * Checks if the object is null or empty.
 */
+ (BOOL)isNullOrEmpty:(id _Nullable)obj;

/**
 * Checks if the string is empty or have spaces.
 */
+ (BOOL)isBlank:(id _Nullable)obj;

/**
 * Computes MD5 of NSData. Mostly used for uploading images.
 */
+ (NSString * _Nonnull)md5OfData:(NSData * _Nullable)data;

/**
 * Returns base64 encoded string from NSData. Convenience method
 * that supports iOS6.
 */
+ (NSString * _Nonnull)base64EncodedStringFromData:(NSData * _Nonnull)data;

/**
 * Initialize exception handling
 */
+ (void)initExceptionHandling;

/**
 * Report an exception
 */
+ (void)handleException:(NSException * _Nonnull)exception;

/**
 * Whether swizzling flag is setup in plist file
 */
+ (BOOL)isSwizzlingEnabled;

/**
 * Returns Leanplum bundle
 */
+ (NSBundle * _Nullable)leanplumBundle;

/**
 * Open URLs from SDK
 */
+ (void)openURL:(NSURL * _Nonnull)url;

/**
 * Open URLs from SDK and calls the completionHandler
 */
+ (void)openURL:(NSURL * _Nonnull)url completionHandler:(void (^ __nullable)(BOOL success))completion;

/**
 * Checks if given value is a NSNumber with bool value
 */
+ (BOOL)isBoolNumber:(NSNumber * _Nonnull)value;

@end
