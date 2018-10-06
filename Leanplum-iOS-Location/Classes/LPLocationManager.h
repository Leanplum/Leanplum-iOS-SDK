//
//  LPLocationManager.h
//  Version 2.0.6
//
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

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface LPLocationManager : NSObject <CLLocationManagerDelegate>

+ (LPLocationManager *)sharedManager;

/**
 * Set before [Leanplum start].
 * Chooses whether to authorize the location permission automatically when the app starts.
 * Call -authorize if needsAuthorization returns YES.
 */
@property (nonatomic, assign) BOOL authorizeAutomatically;

/**
 * Returns YES if the user has not given the appropriate level of permissions for location access.
 * You should call -authorize if needsAuthorization is YES and authorizeAutomatically is NO.
 */
@property (nonatomic, readonly) BOOL needsAuthorization;

/**
 * Authorizes location access by prompting the user for permission.
 * Prompts for use within the app if there are active in-app messages using regions.
 * Prompts for use in the background if there are active push notifications using regions.
 */
- (void)authorize;

@end
