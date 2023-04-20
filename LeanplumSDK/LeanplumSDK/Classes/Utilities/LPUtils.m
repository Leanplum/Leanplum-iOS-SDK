//
//  LPUtils.m
//  Leanplum
//
//  Created by Ben Marten on 6/6/16.
//  Copyright (c) 2023 Leanplum, Inc. All rights reserved.
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

#import "LPUtils.h"
#import <CommonCrypto/CommonDigest.h>
#import "LPConstants.h"
#import "Leanplum.h"
#import <Leanplum/Leanplum-Swift.h>

@implementation LPUtils

+ (BOOL)isNullOrEmpty:(id)obj
{
    // Need to check for NSString to support RubyMotion.
    // Ruby String respondsToSelector(count) is true for count: in RubyMotion
    return obj == nil
    || ([obj respondsToSelector:@selector(length)] && [obj length] == 0)
    || ([obj respondsToSelector:@selector(count)]
        && ![obj isKindOfClass:[NSString class]] && [obj count] == 0);
}

+ (BOOL)isBlank:(NSString *)str
{
    return [[str stringByTrimmingCharactersInSet:
             [NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@""];
}

+ (NSString *)md5OfData:(NSData *)data
{
    if ([LPUtils isNullOrEmpty:data]) {
        return @"";
    }

    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5(data.bytes, (CC_LONG)data.length, digest);
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH*2];
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [output appendFormat:@"%02x", digest[i]];
    }
    return output;
}

+ (NSString *)base64EncodedStringFromData:(NSData *)data
{
    if ([data respondsToSelector:
         @selector(base64EncodedStringWithOptions:)]) {
        return [data base64EncodedStringWithOptions:0];
    }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    return [data base64Encoding];
#pragma clang diagnostic pop

}

+(BOOL)isSwizzlingEnabled
{
    BOOL swizzlingEnabled = YES;
    
    id plistValue = [[[NSBundle mainBundle] infoDictionary] valueForKey:LP_SWIZZLING_ENABLED];
    if (plistValue && ![plistValue boolValue]) {
        swizzlingEnabled = NO;
    }

    return swizzlingEnabled;
}

+ (NSBundle *)leanplumBundle
{
    NSBundle *bundle = [NSBundle bundleForClass:[Leanplum class]];
    NSURL *bundleUrl = [bundle URLForResource:@"Leanplum-iOS-SDK" withExtension:@".bundle"];
    if (bundleUrl != nil)
    {
        NSBundle *lpBundle = [NSBundle bundleWithURL:bundleUrl];
        bundle = lpBundle;
    }
    
    return bundle;
}

+ (void)openURL:(NSURL *)url
{
    [self openURL:url completionHandler:nil];
}

+ (void)openURL:(NSURL *)url completionHandler:(void (^ __nullable)(BOOL success))completion
{
    if (@available(iOS 10.0, *)) {
        [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:completion];
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        [[UIApplication sharedApplication] openURL:url];
        if (completion) {
            completion(YES);
        }
#pragma clang diagnostic pop
    }
}

+ (BOOL)isBoolNumber:(NSNumber *)value
{
   CFTypeID boolID = CFBooleanGetTypeID();
   CFTypeID numID = CFGetTypeID((__bridge CFTypeRef)(value));
   return numID == boolID;
}

+ (void)dispatchOnMainQueue:(void (^_Nonnull)(void))block
{
    if ([NSThread isMainThread]) {
        block();
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            block();
        });
    }
}

@end
