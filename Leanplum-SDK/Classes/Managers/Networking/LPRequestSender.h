//
//  LPRequestSender.h
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
#import "LPRequest.h"

@interface LPRequestSender : NSObject

+ (instancetype)sharedInstance;

- (NSMutableDictionary *)createArgsDictionaryForRequest:(LPRequest *)request;
- (void)attachApiKeys:(NSMutableDictionary *)dict;

- (void)send:(LPRequest *)request;
- (void)sendNow:(LPRequest *)request;
- (void)sendEventually:(LPRequest *)request sync:(BOOL)sync;
- (void)sendIfConnected:(LPRequest *)request;
- (void)sendIfConnected:(LPRequest *)request sync:(BOOL)sync;
// Sends the request if another request hasn't been sent within a particular time delay.
- (void)sendIfDelayed:(LPRequest *)request;

/**
 * Sends one data. Uses sendDatasNow: internally. See this method for more information.
 */
- (void)sendNow:(LPRequest *)request withData:(NSData *)data forKey:(NSString *)key;

/**
 * Send datas where key is the name and object is the data.
 * For example, key can be "file0" and object is NSData of png.
 */
- (void)sendNow:(LPRequest *)request withDatas:(NSDictionary *)datas;

@end
