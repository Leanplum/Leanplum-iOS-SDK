//
//  LPCrashHandler.h
//  Leanplum iOS SDK Version 2.0.6
//
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

#import "LPCrashHandler.h"

@interface LPCrashHandler()

@property (nonatomic, strong) id<LPCrashReporting> crashReporter;

@end

@implementation LPCrashHandler

+(instancetype)sharedCrashHandler
{
    static LPCrashHandler *sharedCrashHandler = nil;
    @synchronized(self) {
        if (!sharedCrashHandler) {
            sharedCrashHandler = [[self alloc] init];
        }
    }
    return sharedCrashHandler;
}

-(instancetype)init
{
    self = [super init];
    if (self) {
        [self initializeRaygunReporter];
    }
    return self;
}

-(void)initializeRaygunReporter
{
    _crashReporter = [[NSClassFromString(@"LPRaygunCrashReporter") alloc] init];
    
}

-(void)reportException:(NSException *)exception
{
    if (self.crashReporter) {
        [self.crashReporter reportException:exception];
    }
}

@end
