//
//  LPNetworkFactory.m
//  Leanplum
//
//  Created by Alexis Oyama on 11/14/16.
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

#import "LPNetworkFactory.h"
#import "LPNetworkEngine.h"
#import "LPNetworkOperation.h"
#import "Leanplum_MKNKOperationWrapper.h"
#import "Leanplum_MKNKEngineWrapper.h"

@implementation LPNetworkFactory

+ (id<LPNetworkEngineProtocol>)engineWithHostName:(NSString*)hostName
                               customHeaderFields:(NSDictionary*)headers
{
#if __IPHONE_OS_VERSION_MIN_REQUIRED < 70000
    if (!NSClassFromString(@"NSURLSession")) {
        return [[Leanplum_MKNKEngineWrapper alloc] initWithHostName:hostName
                                                 customHeaderFields:headers];
    }
#endif
    return [[LPNetworkEngine alloc] initWithHostName:hostName
                                  customHeaderFields:headers];
}

+ (id<LPNetworkEngineProtocol>)engineWithHostName:(NSString*)hostName
{
#if __IPHONE_OS_VERSION_MIN_REQUIRED < 70000
    if (!NSClassFromString(@"NSURLSession")) {
        return [[Leanplum_MKNKEngineWrapper alloc] initWithHostName:hostName];
    }
#endif
    return [[LPNetworkEngine alloc] initWithHostName:hostName];
}

+ (NSString *)fileRequestMethod
{
#if __IPHONE_OS_VERSION_MIN_REQUIRED < 70000
    if (!NSClassFromString(@"NSURLSession")) {
        return [Leanplum_MKNKOperationWrapper fileRequestMethod];
    }
#endif
    return [LPNetworkOperation fileRequestMethod];
}

@end
