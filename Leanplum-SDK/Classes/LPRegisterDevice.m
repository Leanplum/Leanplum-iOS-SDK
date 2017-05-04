//
//  RegisterDevice.m
//  Leanplum
//
//  Created by Andrew First on 5/13/12.
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

#import "LPRegisterDevice.h"
#import "LeanplumRequest.h"
#import "Constants.h"

@implementation LPRegisterDevice

- (id)initWithCallback:(LeanplumStartBlock)callback_
{
    if (self = [super init]) {
        self->callback = callback_;
    }
    return self;
}

- (void)showError:(NSString *)message
{
    NSLog(@"Leanplum: Device registration error: %@", message);
    self->callback(NO);
}

- (void)registerDevice:(NSString *)email
{
    LeanplumRequest *request = [LeanplumRequest post:LP_METHOD_REGISTER_FOR_DEVELOPMENT
                                              params:@{ LP_PARAM_EMAIL: email }];
    [request onResponse:^(id<LPNetworkOperationProtocol> operation, id json) {
        LP_TRY
        NSDictionary* registerResponse = [LPResponse getLastResponse:json];
        BOOL isSuccess = [LPResponse isResponseSuccess:registerResponse];
        if (isSuccess) {
            self->callback(YES);
        } else {
            [self showError:[LPResponse getResponseError:registerResponse]];
        }
        LP_END_TRY
    }];
    [request onError:^(NSError *error) {
        [self showError:[error localizedDescription]];
    }];
    [request sendNow];
}

@end
