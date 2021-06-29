//
//  LPEnumConstants.h
//  Leanplum-SDK
//
//  Created by Grace Gu on 12/19/18.
//  Copyright © 2018 Leanplum. All rights reserved.
//
//  Licensed to the Apache Software Foundation (ASF) under one
//  or more contributor license agreements.  See the NOTICE file
//  distributed with this work for additional information
//  regarding copyright ownership.  The ASF licenses this file
//  to you under the Apache License, Version 2.0 (the “License”);
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing,
//  software distributed under the License is distributed on an
//  “AS IS” BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
//  KIND, either express or implied.  See the License for the
//  specific language governing permissions and limitations
//  under the License.

#include <Foundation/Foundation.h>

#ifndef EnumConstants_h
#define EnumConstants_h

@interface LPEnumConstants : NSObject {}

typedef NS_ENUM(NSUInteger, LPGeofenceEventType) {
    LPEnterRegion,
    LPExitRegion
} NS_SWIFT_NAME(Leanplum.GeofenceEventType);


+ (NSString *)getEventNameFromGeofenceType:(LPGeofenceEventType)event;
@end

#endif /* EnumConstants_h */
