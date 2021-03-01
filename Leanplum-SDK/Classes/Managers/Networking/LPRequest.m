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
#import "LPCountAggregator.h"
#import "LPNetworkConstants.h"
#import "LPConstants.h"
#import "LPAPIConfig.h"

@interface LPRequest()

@property (nonatomic, strong) NSString *apiMethod;
@property (nonatomic, strong, nullable) NSDictionary *params;
@property (nonatomic, strong) NSString *httpMethod;
@property (nonatomic, strong) LPCountAggregator *countAggregator;

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
        _countAggregator = [LPCountAggregator sharedAggregator];
        _requestId = [[NSUUID UUID] UUIDString];
        _requestType = Default;
    }
    return self;
}

- (LPRequest *)andRequestType:(LPRequestType)type
{
    self.requestType = type;
    return self;
}

+ (LPRequest *)get:(NSString *)apiMethod params:(NSDictionary *)params
{
    LPLog(LPDebug, @"Will call API method %@ with arguments %@", apiMethod, params);
    
    [[LPCountAggregator sharedAggregator] incrementCount:@"get_lprequest"];
    
    return [[LPRequest alloc] initWithHttpMethod:@"GET" apiMethod:apiMethod params:params];
}

+ (LPRequest *)post:(NSString *)apiMethod params:(NSDictionary *)params
{
    LPLog(LPDebug, @"Will call API method %@ with arguments %@", apiMethod, params);
    
    [[LPCountAggregator sharedAggregator] incrementCount:@"post_lpquest"];
    
    return [[LPRequest alloc] initWithHttpMethod:@"POST" apiMethod:apiMethod params:params];
}

- (void)onResponse:(LPNetworkResponseBlock)responseBlock
{
    self.responseBlock = responseBlock;
    
    [self.countAggregator incrementCount:@"on_response_lprequest"];
}

- (void)onError:(LPNetworkErrorBlock)errorBlock
{
    self.errorBlock = errorBlock;
    
    [self.countAggregator incrementCount:@"on_error_lprequest"];
}

- (NSMutableDictionary *)createArgsDictionary
{
    LPConstantsState *constants = [LPConstantsState sharedState];
    NSString *timestamp = [NSString stringWithFormat:@"%f", [[NSDate date] timeIntervalSince1970]];
    NSMutableDictionary *args = [@{
                                   LP_PARAM_ACTION: self.apiMethod,
                                   LP_PARAM_DEVICE_ID: [LPAPIConfig sharedConfig].deviceId ?: @"",
                                   LP_PARAM_USER_ID: [LPAPIConfig sharedConfig].userId ?: @"",
                                   LP_PARAM_SDK_VERSION: constants.sdkVersion,
                                   LP_PARAM_CLIENT: constants.client,
                                   LP_PARAM_DEV_MODE: @(constants.isDevelopmentModeEnabled),
                                   LP_PARAM_TIME: timestamp,
                                   LP_PARAM_REQUEST_ID: self.requestId,
                                   } mutableCopy];
    if ([LPAPIConfig sharedConfig].token) {
        args[LP_PARAM_TOKEN] = [LPAPIConfig sharedConfig].token;
    }
    if (self.params && self.params.count > 0) {
        [args addEntriesFromDictionary:self.params];
    }
    
    // remove keys that are empty
    [args removeObjectForKey:@""];
    
    return args;
}

@end
