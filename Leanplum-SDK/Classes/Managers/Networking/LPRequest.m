//
//  LPRequest.h
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

#import "LeanplumInternal.h"
#import "LPRequest.h"

@interface LPRequest()

@property (nonatomic, strong) NSString *httpMethod;

@end

@implementation LPRequest

- (id)initWithHttpMethod:(NSString *)httpMethod
               apiMethod:(NSString *)apiMethod
                  params:(NSDictionary *)params {
    self = [super init];
    if (self) {
        _httpMethod = httpMethod;
        _apiMethod = apiMethod;
        _params = params;
    }
    return self;
}

+ (LPRequest *)get:(NSString *)apiMethod params:(NSDictionary *)params
{
    LPLogType level = [apiMethod isEqualToString:LP_METHOD_LOG] ? LPDebug : LPVerbose;
    LPLog(level, @"Will call API method %@ with arguments %@", apiMethod, params);
    return [[LPRequest alloc] initWithHttpMethod:@"GET" apiMethod:apiMethod params:params];
}

+ (LPRequest *)post:(NSString *)apiMethod params:(NSDictionary *)params
{
    LPLogType level = [apiMethod isEqualToString:LP_METHOD_LOG] ? LPDebug : LPVerbose;
    LPLog(level, @"Will call API method %@ with arguments %@", apiMethod, params);
    return [[LPRequest alloc] initWithHttpMethod:@"POST" apiMethod:apiMethod params:params];
}

- (void)onResponse:(LPNetworkResponseBlock)responseBlock
{
    self.responseBlock = responseBlock;
}

- (void)onError:(LPNetworkErrorBlock)errorBlock
{
    self.errorBlock = errorBlock;
}

@end
