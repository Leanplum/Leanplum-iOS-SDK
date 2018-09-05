//
//  LPRequestFactory.h
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
#import "LPRequesting.h"
#import "LPFeatureFlagManager.h"

@interface LPRequestFactory : NSObject

-(instancetype)initWithFeatureFlagManager:(LPFeatureFlagManager *)featureFlagManager;

- (id<LPRequesting>)startWithParams:(NSDictionary *)params;
- (id<LPRequesting>)getVarsWithParams:(NSDictionary *)params;
- (id<LPRequesting>)setVarsWithParams:(NSDictionary *)params;
- (id<LPRequesting>)stopWithParams:(NSDictionary *)params;
- (id<LPRequesting>)restartWithParams:(NSDictionary *)params;
- (id<LPRequesting>)trackWithParams:(NSDictionary *)params;
- (id<LPRequesting>)advanceWithParams:(NSDictionary *)params;
- (id<LPRequesting>)pauseSessionWithParams:(NSDictionary *)params;
- (id<LPRequesting>)pauseStateWithParams:(NSDictionary *)params;
- (id<LPRequesting>)resumeSessionWithParams:(NSDictionary *)params;
- (id<LPRequesting>)resumeStateWithParams:(NSDictionary *)params;
- (id<LPRequesting>)multiWithParams:(NSDictionary *)params;
- (id<LPRequesting>)registerDeviceWithParams:(NSDictionary *)params;
- (id<LPRequesting>)setUserAttributesWithParams:(NSDictionary *)params;
- (id<LPRequesting>)setDeviceAttributesWithParams:(NSDictionary *)params;
- (id<LPRequesting>)setTrafficSourceInfoWithParams:(NSDictionary *)params;
- (id<LPRequesting>)uploadFileWithParams:(NSDictionary *)params;
- (id<LPRequesting>)downloadFileWithParams:(NSDictionary *)params;
- (id<LPRequesting>)heartbeatWithParams:(NSDictionary *)params;
- (id<LPRequesting>)saveInterfaceWithParams:(NSDictionary *)params;
- (id<LPRequesting>)saveInterfaceImageWithParams:(NSDictionary *)params;
- (id<LPRequesting>)getViewControllerVersionsListWithParams:(NSDictionary *)params;
- (id<LPRequesting>)logWithParams:(NSDictionary *)params;
- (id<LPRequesting>)getNewsfeedMessagesWithParams:(NSDictionary *)params;
- (id<LPRequesting>)markNewsfeedMessageAsReadWithParams:(NSDictionary *)params;
- (id<LPRequesting>)deleteNewsfeedMessageWithParams:(NSDictionary *)params;

@end
