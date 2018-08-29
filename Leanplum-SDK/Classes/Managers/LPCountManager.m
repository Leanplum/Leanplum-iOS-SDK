//
//  LPCountManager.m
//  Leanplum
//
//  Created by Grace Gu on 8/27/18.
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

#import "LPCountManager.h"
#import "LPVarCache.h"

@interface LPCountManager()

@property (nonatomic, strong) NSMutableDictionary *counts;
@property (nonatomic, strong) NSSet *enabledCounters;

//static NSMutableDictionary *counts;

@end

@implementation LPCountManager

static LPCountManager *sharedCountManager = nil;
static dispatch_once_t leanplum_onceToken;

+ (instancetype)sharedManager {
    dispatch_once(&leanplum_onceToken, ^{
        sharedCountManager = [[self alloc] init];
    });
    return sharedCountManager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        if (!self.counts) {
            self.counts = [[NSMutableDictionary alloc] init];
        }
    }
    return self;
}

- (NSSet *)enabledCounters {
    return self.enabledCounters;
}

- (void)setEnabledCounters:(NSSet *)_enabledCounters {
    self.enabledCounters = _enabledCounters;
}

- (void)incrementCount:(NSString *)name {
    if ([self.enabledCounters containsObject:name]) {
        int count = 0;
        if ([self.counts objectForKey:name]) {
            count = [self.counts[name] intValue];
        }
        count = count + 1;
        self.counts[name] = [NSNumber numberWithInt:count];
    }
}

- (NSDictionary *)getAndClearCounts {
    NSDictionary *previousCounts = [[NSDictionary alloc]initWithDictionary:self.counts];
    [self.counts removeAllObjects];
    return previousCounts;
}

@end
