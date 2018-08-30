//
//  LPRequestStorage.h
//  Leanplum
//
//  Created by Andrew First on 10/23/14.
//  Copyright (c) 2014 Leanplum, Inc. All rights reserved.
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

/**
 * Request Storage is deprecated from 2.0.2.
 * Use LPEventDataManager instead. 
 * Do not use this class other than migrating.
 */
@interface LPRequestStorage : NSObject {
    @private
    NSTimeInterval _lastSentTime;
}

@property (nonatomic, readonly) NSTimeInterval lastSentTime;

+ (LPRequestStorage *)sharedStorage;

/**
 * Push request to file by read, append, and then write.
 */
- (void)pushRequest:(NSDictionary *)requestData;

/**
 * Push multiple requests to file by read, append, and then write.
 */
- (void)pushRequests:(NSArray *)requestDatas;

/**
 * Read all requests and delete the file.
 */
- (NSArray *)popAllRequests;

/**
 * This file path returns the one in documents directory. Requests should be stored here.
 */
- (NSString *)documentsFilePath;

@end
