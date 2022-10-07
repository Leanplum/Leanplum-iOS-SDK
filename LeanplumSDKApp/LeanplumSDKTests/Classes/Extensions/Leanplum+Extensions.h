//
//  Leanplum+Extensions.h
//  Leanplum-SDK
//
//  Created by Milos Jakovljevic on 10/17/16.
//  Copyright © 2016 Leanplum. All rights reserved.
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


#import <Leanplum/Leanplum.h>
#import <Leanplum/LeanplumInternal.h>
#import <Leanplum/LPRequestFactory.h>
#import <Leanplum/Leanplum-Swift.h>

NS_ASSUME_NONNULL_BEGIN

@interface Leanplum(UnitTest)

@property (class, readonly) User* _Nonnull user;

+ (NSLocale * _Nullable)systemLocale;

+ (void)reset;

+ (void)maybePerformActions:(NSArray *)whenConditions
              withEventName:(NSString *)eventName
                 withFilter:(LeanplumActionFilter)filter
              fromMessageId:(NSString *)sourceMessage
       withContextualValues:(LPContextualValues *)contextualValues;

+ (void)triggerAction:(LPActionContext *)context handledBlock:(LeanplumHandledBlock)handledBlock;

+ (void)setDeviceIdInternal:(NSString *)deviceId;

@end

NS_ASSUME_NONNULL_END

@interface LPActionContext(UnitTest)

+ (nullable  LPActionContext *)actionContextWithName:(nonnull NSString *)name
                                      args:(nullable NSDictionary *)args
                                 messageId:(nullable NSString *)messageId;

-(nullable NSString *)htmlStringContentsOfFile:(nonnull NSString *)file;

@end

@interface LPRequestFactory(UnitTest)
+ (nullable LPRequest *)createGetForApiMethod:(nonnull NSString *)apiMethod params:(nullable NSDictionary *)params;
+ (nullable LPRequest *)createPostForApiMethod:(nonnull NSString *)apiMethod params:(nullable NSDictionary *)params;
@end

@interface LPLogManager(UnitTest)
+ (void)maybeSendLog:(nonnull NSString *)message;
@end


@interface ApiConfig(UnitTest)
@property (strong, nonatomic, nonnull) NSString *appId;
@property (strong, nonatomic, nonnull) NSString *accessKey;
@end
