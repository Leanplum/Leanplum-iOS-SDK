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

#import <Foundation/Foundation.h>
#import "Leanplum.h"
#import "LPNetworkFactory.h"

NS_ASSUME_NONNULL_BEGIN
typedef NS_ENUM(NSUInteger, LPRequestType) {
    Default = 0,
    Immediate
} NS_SWIFT_NAME(Leanplum.RequestType);

@interface LPRequest : NSObject

@property (atomic) BOOL sent;
@property (nonatomic, copy, nullable) LPNetworkResponseBlock responseBlock;
@property (nonatomic, copy, nullable) LPNetworkErrorBlock errorBlock;
@property (nonatomic, strong) NSString *requestId;
@property (nonatomic, assign) LPRequestType requestType;
@property (nonatomic, strong, nullable) NSDictionary *datas;

+ (LPRequest *)get:(NSString *)apiMethod params:(nullable NSDictionary *)params;
+ (LPRequest *)post:(NSString *)apiMethod params:(nullable NSDictionary *)params;

- (LPRequest *)andRequestType:(LPRequestType)type;
- (void)onResponse:(nullable LPNetworkResponseBlock)response;
- (void)onError:(nullable LPNetworkErrorBlock)error;

- (NSMutableDictionary *)createArgsDictionary;

@end
NS_ASSUME_NONNULL_END
