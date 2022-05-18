//
//  VarCache.h
//  Leanplum
//
//  Created by Andrew First on 5/2/12.
//  Copyright (c) 2012 Leanplum, Inc. All rights reserved.
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
#import "LPSecuredVars.h"

NS_ASSUME_NONNULL_BEGIN

@class LPVar;

typedef void (^CacheUpdateBlock)(void);
typedef void (^RegionInitBlock)(NSDictionary *, NSSet *, NSSet *);

NS_SWIFT_NAME(VarCache)
@interface LPVarCache : NSObject

- (instancetype)init NS_UNAVAILABLE;

+(instancetype)sharedCache
NS_SWIFT_NAME(shared());

// Location initialization
- (void)registerRegionInitBlock:(RegionInitBlock)block;

// Handling variables.
- (LPVar *)define:(NSString *)name
             with:(nullable NSObject *)defaultValue
             kind:(nullable NSString *)kind
NS_SWIFT_NAME(define(name:value:kind:));

- (NSArray<NSString *> *)getNameComponents:(NSString *)name;
- (void)loadDiffs;
- (void)saveDiffs;

- (void)registerVariable:(LPVar *)var;
- (nullable LPVar *)getVariable:(NSString *)name;

// Handling values.
- (nullable id)getValueFromComponentArray:(NSArray<NSString *> *) components fromDict:(NSDictionary<NSString *, id> *)values;
- (nullable id)getMergedValueFromComponentArray:(NSArray<NSString *> *) components;
- (nullable NSDictionary<NSString *, id> *)diffs;
- (BOOL)hasReceivedDiffs;
- (void)applyVariableDiffs:(nullable NSDictionary<NSString *, id> *)diffs_
                  messages:(nullable NSDictionary<NSString *, id> *)messages_
                  variants:(nullable NSArray<NSString *> *)variants_
                 localCaps:(nullable NSArray<NSDictionary *> *)localCaps_
                   regions:(nullable NSDictionary<NSString *, id> *)regions_
          variantDebugInfo:(nullable NSDictionary<NSString *, id> *)variantDebugInfo_
                  varsJson:(nullable NSString *)varsJson_
             varsSignature:(nullable NSString *)varsSignature_;
- (void)onUpdate:(CacheUpdateBlock)block;
- (void)setSilent:(BOOL)silent;
- (BOOL)silent;
- (int)contentVersion;
- (nullable NSArray<NSString *> *)variants;
- (nullable NSDictionary<NSString *, id> *)regions;
- (nullable NSDictionary<NSString *, id> *)defaultKinds;

- (nullable NSDictionary<NSString *, id> *)variantDebugInfo;
- (void)setVariantDebugInfo:(nullable NSDictionary<NSString *, id> *)variantDebugInfo;

- (void)clearUserContent;

- (NSArray<NSDictionary *> *)getLocalCaps;

// Development mode.
- (void)setDevModeValuesFromServer:(nullable NSDictionary<NSString *, id> *)values
                    fileAttributes:(nullable NSDictionary<NSString *, id> *)fileAttributes
                 actionDefinitions:(nullable NSDictionary<NSString *, id> *)actionDefinitions;
- (BOOL)sendVariablesIfChanged;
- (BOOL)sendActionsIfChanged;

// Handling files.
- (void)registerFile:(NSString *)stringValue withDefaultValue:(NSString *)defaultValue;
- (void)maybeUploadNewFiles;
- (nullable NSDictionary<NSString *, id> *)fileAttributes;

- (nullable NSMutableDictionary<NSString *, id> *)userAttributes;
- (void)saveUserAttributes;

- (LPSecuredVars *)securedVars;

@end

NS_ASSUME_NONNULL_END
