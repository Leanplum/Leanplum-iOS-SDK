//
//  MessageTemplatesTest.m
//  Leanplum-SDK-Tests
//
//  Created by Milos Jakovljevic on 6/16/17.
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


#import <XCTest/XCTest.h>
#import <UIKit/UIKit.h>
#import <OHHTTPStubs/HTTPStubs.h>
#import <OHHTTPStubs/HTTPStubsPathHelpers.h>
#import "LeanplumHelper.h"
#import "LeanplumRequest+Categories.h"
#import "Leanplum+Extensions.h"
#import "LPActionManager.h"
#import "LPConstants.h"
#import "LPRegisterDevice.h"
#import "LPMessageTemplates.h"

@interface LPMessageTemplatesClassTest : XCTestCase

@end

@implementation LPMessageTemplatesClassTest

+ (void)setUp
{
    [super setUp];
    // Called only once to setup method swizzling.
    [LeanplumHelper setup_method_swizzling];
}

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
    // Clean up after every test.
    [LeanplumHelper clean_up];
    [HTTPStubs removeAllStubs];
}

-(void)test_shared_templates_creation
{
    // Previously, this was causing a deadlock.
    [LPMessageTemplatesClass sharedTemplates];
}

@end
