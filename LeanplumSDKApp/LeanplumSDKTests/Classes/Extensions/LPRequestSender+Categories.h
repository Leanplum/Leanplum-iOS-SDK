//
//  LPRequestSender+Extensions.h
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


#import <Leanplum/LPRequestSender.h>

@interface LPRequestSender(MethodSwizzling)

@property (assign) BOOL (^requestCallback)(NSString *method, NSString *apiMethod, NSDictionary *params);
@property (assign) void (^createArgsCallback)(NSDictionary *args);

- (void)setRequestCallback:(BOOL (^)(NSString *, NSString *, NSDictionary *))requestCallback;
- (BOOL (^)(NSString *, NSString *, NSDictionary *))requestCallback;

- (void)setCreateArgsCallback:(void (^)(NSDictionary *))createArgsCallback;
- (void (^)(NSDictionary *))createArgsCallback;

+ (void)validate_request:(BOOL (^)(NSString *, NSString *, NSDictionary *))callback;
+ (void)validate_request_args_dictionary:(void (^)(NSDictionary *))callback;
+ (void)swizzle_methods;
+ (void)unswizzle_methods;
+ (void)reset;

@end
