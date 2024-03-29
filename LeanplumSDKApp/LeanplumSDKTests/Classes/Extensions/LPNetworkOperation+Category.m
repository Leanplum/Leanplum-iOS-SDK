//
//  LPNetworkOperation+Category.m
//  Leanplum-SDK-Tests
//
//  Created by Alexis Oyama on 6/15/17.
//  Copyright © 2017 Leanplum. All rights reserved.
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


#import "LPNetworkOperation+Category.h"
#import <Leanplum/LPSwizzle.h>
#import <Leanplum/LPNetworkOperation.h>

@implementation LPNetworkOperation (MethodSwizzling)

+ (void)swizzle_methods
{
    NSError *error;
    bool success = [LPSwizzle swizzleMethod:@selector(runSynchronously:)
                                 withMethod:@selector(swizzle_runSynchronously:)
                                      error:&error
                                      class:[LPNetworkOperation class]];
    if (!success || error) {
        NSLog(@"Failed swizzling methods for LPNetworkOperation: %@", error);
    }
}

+ (void)unswizzle_methods
{
    NSError *error;
    bool success = [LPSwizzle swizzleMethod:@selector(swizzle_runSynchronously:)
                                 withMethod:@selector(runSynchronously:)
                                      error:&error
                                      class:[LPNetworkOperation class]];
    if (!success || error) {
        NSLog(@"Failed swizzling methods for LPNetworkOperation: %@", error);
    }
}

- (void)swizzle_runSynchronously:(BOOL)synchronous
{
    [self swizzle_runSynchronously:YES];
}

@end
