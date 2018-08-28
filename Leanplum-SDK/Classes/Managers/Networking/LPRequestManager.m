//
//  LPRequestManager.m
//  Leanplum
//
//  Created by Mayank Sanganeria on 6/30/18.
//  Copyright (c) 2018 Leanplum, Inc. All rights reserved.
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

#import "LPRequestManager.h"
#import "LeanplumInternal.h"
#import "LPRequest.h"
#import "LeanplumRequest.h"
#import "LPResponse.h"
#import "LPKeychainWrapper.h"
#import "LPEventDataManager.h"
#import "LPEventCallbackManager.h"

@interface LeanplumRequest(LPRequestManager)

- (void)sendNow:(BOOL)async;

@end


@interface LPRequestManager()

@end


@implementation LPRequestManager

+ (instancetype)sharedManager {
    static LPRequestManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] init];
    });
    return sharedManager;
}

- (void)sendRequest:(id<LPRequesting>)request
{
    if ([request isKindOfClass:[LeanplumRequest class]]) {
        LeanplumRequest *oldLeanplumRequest = request;
        [oldLeanplumRequest send];
    }
}

- (void)sendNowRequest:(id<LPRequesting>)request
{
    if ([request isKindOfClass:[LeanplumRequest class]]) {
        LeanplumRequest *oldLeanplumRequest = request;
        [oldLeanplumRequest sendNow];
    }
}

- (void)sendEventuallyRequest:(id<LPRequesting>)request
{
    if ([request isKindOfClass:[LeanplumRequest class]]) {
        LeanplumRequest *oldLeanplumRequest = request;
        [oldLeanplumRequest sendEventually];
    }
}

- (void)sendIfConnectedRequest:(id<LPRequesting>)request
{
    if ([request isKindOfClass:[LeanplumRequest class]]) {
        LeanplumRequest *oldLeanplumRequest = request;
        [oldLeanplumRequest sendIfConnected];
    }
}

- (void)sendIfConnectedSync:(BOOL)sync request:(id<LPRequesting>)request
{
    if ([request isKindOfClass:[LeanplumRequest class]]) {
        LeanplumRequest *oldLeanplumRequest = request;
        [oldLeanplumRequest sendIfConnectedSync:sync];
    }
}

- (void)sendIfDelayedRequest:(id<LPRequesting>)request
{
    if ([request isKindOfClass:[LeanplumRequest class]]) {
        LeanplumRequest *oldLeanplumRequest = request;
        [oldLeanplumRequest sendIfDelayed];
    }
}

- (void)sendDataNow:(NSData *)data forKey:(NSString *)key request:(id<LPRequesting>)request
{
    if ([request isKindOfClass:[LeanplumRequest class]]) {
        LeanplumRequest *oldLeanplumRequest = request;
        [oldLeanplumRequest sendDataNow:data forKey:key];
    }
}

- (void)sendDatasNow:(NSDictionary *)datas request:(id<LPRequesting>)request
{
    if ([request isKindOfClass:[LeanplumRequest class]]) {
        LeanplumRequest *oldLeanplumRequest = request;
        [oldLeanplumRequest sendDatasNow:datas];
    }
}

- (void)sendNow:(BOOL)async request:(id<LPRequesting>)request
{
    if ([request isKindOfClass:[LeanplumRequest class]]) {
        LeanplumRequest *oldLeanplumRequest = request;
        [oldLeanplumRequest sendNow:YES];
    }
}

@end
