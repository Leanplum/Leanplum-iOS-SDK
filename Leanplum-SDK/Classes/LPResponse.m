//
//  LeanplumRequest.m
//  Leanplum
//
//  Created by Andrew First on 4/30/12.
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

#import "Leanplum.h"
#import "LeanplumInternal.h"
#import "LeanplumRequest.h"
#import "LPResponse.h"
#import "Constants.h"
#import "LPFileManager.h"
#import "NSTimer+Blocks.h"
#import "LPKeychainWrapper.h"
#import "LPEventDataManager.h"
#import "LPEventCallbackManager.h"

@implementation LPResponse

+ (NSUInteger)numResponsesInDictionary:(NSDictionary *)dictionary
{
    return [dictionary[@"response"] count];
}

+ (NSDictionary *)getResponseAt:(NSUInteger)index fromDictionary:(NSDictionary *)dictionary
{
    if (index < [LPResponse numResponsesInDictionary:dictionary]) {
        return [dictionary[@"response"] objectAtIndex:index];
    }
    return [dictionary[@"response"] lastObject];
}

+ (NSDictionary *)getLastResponse:(NSDictionary *)dictionary
{
    return [LPResponse getResponseAt:[LPResponse numResponsesInDictionary:dictionary] - 1
                      fromDictionary:dictionary];
}

+ (BOOL)isResponseSuccess:(NSDictionary *)dictionary
{
    return [dictionary[@"success"] boolValue];
}

+ (NSString *)getResponseError:(NSDictionary *)dictionary
{
    return dictionary[@"error"][@"message"];
}

@end
