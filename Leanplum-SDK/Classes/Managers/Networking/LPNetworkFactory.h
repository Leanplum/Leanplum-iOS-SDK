//
//  LPNetworkFactory.h
//  Leanplum
//
//  Created by Alexis Oyama on 11/14/16.
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
#import "LPNetworkProtocol.h"

/**
 * Network Factory that creates an engine depending if
 * device has NSURLSession (iOS > 7).
 */
@interface LPNetworkFactory : NSObject

+ (id<LPNetworkEngineProtocol>)engineWithHostName:(NSString*)hostName
                               customHeaderFields:(NSDictionary*)headers;
+ (id<LPNetworkEngineProtocol>)engineWithHostName:(NSString*)hostName;

/**
 * Workaround to use POST on new and GET on old networking library.
 */
+ (NSString *)fileRequestMethod;

@end
