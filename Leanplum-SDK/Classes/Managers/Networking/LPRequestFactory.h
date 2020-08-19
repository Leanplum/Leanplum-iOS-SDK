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
#import "LPRequest.h"
#import "LPFeatureFlagManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface LPRequestFactory : NSObject

+ (LPRequest *)startWithParams:(nullable NSDictionary *)params;
+ (LPRequest *)getVarsWithParams:(nullable NSDictionary *)params;
+ (LPRequest *)setVarsWithParams:(nullable NSDictionary *)params;
+ (LPRequest *)stopWithParams:(nullable NSDictionary *)params;
+ (LPRequest *)restartWithParams:(nullable NSDictionary *)params;
+ (LPRequest *)trackWithParams:(nullable NSDictionary *)params;
+ (LPRequest *)trackGeofenceWithParams:(nullable NSDictionary *)params;
+ (LPRequest *)advanceWithParams:(nullable NSDictionary *)params;
+ (LPRequest *)pauseSessionWithParams:(nullable NSDictionary *)params;
+ (LPRequest *)pauseStateWithParams:(nullable NSDictionary *)params;
+ (LPRequest *)resumeSessionWithParams:(nullable NSDictionary *)params;
+ (LPRequest *)resumeStateWithParams:(nullable NSDictionary *)params;
+ (LPRequest *)multiWithParams:(nullable NSDictionary *)params;
+ (LPRequest *)registerDeviceWithParams:(nullable NSDictionary *)params;
+ (LPRequest *)setUserAttributesWithParams:(nullable NSDictionary *)params;
+ (LPRequest *)setDeviceAttributesWithParams:(nullable NSDictionary *)params;
+ (LPRequest *)setTrafficSourceInfoWithParams:(nullable NSDictionary *)params;
+ (LPRequest *)uploadFileWithParams:(nullable NSDictionary *)params;
+ (LPRequest *)downloadFileWithParams:(nullable NSDictionary *)params;
+ (LPRequest *)heartbeatWithParams:(nullable NSDictionary *)params;
+ (LPRequest *)saveInterfaceWithParams:(nullable NSDictionary *)params;
+ (LPRequest *)saveInterfaceImageWithParams:(nullable NSDictionary *)params;
+ (LPRequest *)getViewControllerVersionsListWithParams:(nullable NSDictionary *)params;
+ (LPRequest *)logWithParams:(nullable NSDictionary *)params;
+ (LPRequest *)getNewsfeedMessagesWithParams:(nullable NSDictionary *)params;
+ (LPRequest *)markNewsfeedMessageAsReadWithParams:(nullable NSDictionary *)params;
+ (LPRequest *)deleteNewsfeedMessageWithParams:(nullable NSDictionary *)params;

@end

NS_ASSUME_NONNULL_END
