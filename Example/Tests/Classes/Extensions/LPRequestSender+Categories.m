//
//  LPRequestSender+Extensions.m
//  Leanplum-SDK
//
//  Created by Milos Jakovljevic on 10/17/16.
//  Copyright © 2016 Leanplum. All rights reserved.
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


#import "LPRequestSender+Categories.h"
#import "LPSwizzle.h"
#import <objc/runtime.h>

@implementation LPRequestSender(MethodSwizzling)
@dynamic requestCallback;

- (void)setRequestCallback:(BOOL (^)(NSString *, NSString *, NSDictionary *))requestCallback
{
    objc_setAssociatedObject(self, @selector(requestCallback), requestCallback, OBJC_ASSOCIATION_COPY);
}

- (BOOL (^)(NSString *, NSString *, NSDictionary *))requestCallback
{
    return objc_getAssociatedObject(self, _cmd);
}

+ (void)swizzle_methods
{
    NSError *error;
    bool success = [LPSwizzle swizzleMethod:@selector(sendNow:)
                                 withMethod:@selector(swizzle_sendNow:)
                                      error:&error
                                      class:[LPRequestSender class]];
    success &= [LPSwizzle swizzleMethod:@selector(sendEventually:sync:)
                             withMethod:@selector(swizzle_sendEventually:sync:)
                                  error:&error
                                  class:[LPRequestSender class]];
    if (!success || error) {
        NSLog(@"Failed swizzling methods for LPRequestSender: %@", error);
    }
}

- (void)swizzle_sendNow:(LPRequest *)request
{
    [self swizzle_sendNow:request];
}

- (void)swizzle_sendEventually:(LPRequest *)request sync:(BOOL)sync
{
    [self swizzle_sendEventually:request sync:sync];
}

- (void)swizzle_download
{

}

+ (void)validate_request:(BOOL (^)(NSString *, NSString *, NSDictionary *)) callback
{
    [LPRequestSender sharedInstance].requestCallback = callback;
}

+ (void)reset {
    [LPRequestSender sharedInstance].requestCallback = nil;
}

@end
