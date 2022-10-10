//
//  LeanplumHelper.m
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



#import <XCTest/XCTest.h>
#import <OHHTTPStubs/HTTPStubs.h>
#import <OHHTTPStubs/HTTPStubsPathHelpers.h>
#import <OCMock/OCMock.h>
#import "Leanplum+Extensions.h"
#import "LPRequestFactory+Extension.h"
#import "LPRequest+Extension.h"
#import "LeanplumHelper.h"
#import "LPRequestSender+Categories.h"
#import "LPVarCache+Extensions.h"
#import <Leanplum/LPActionTriggerManager.h>
#import "LeanplumReachability+Category.h"
#import "LPNetworkEngine+Category.h"
#import "LPNetworkOperation+Category.h"
#import <Leanplum/LPOperationQueue.h>
#import <Leanplum/Leanplum-Swift.h>
#import "LeanplumSDKTests-Swift.h"

// Keys also used in Leanplum-Info.plist file
NSString *APPLICATION_ID = @"app_nLiaLr3lXvCjXhsztS1Gw8j281cPLO6sZetTDxYnaSk";
NSString *DEVELOPMENT_KEY = @"dev_2bbeWLmVJyNrqI8F21Kn9nqyUPRkVCUoLddBkHEyzmk";
NSString *PRODUCTION_KEY = @"prod_XYpURdwPAaxJyYLclXNfACe9Y8hs084dBx2pB8wOnqU";

NSString *API_HOST = @"api.leanplum.com";
NSString *API_PATH = @"api";

NSInteger DISPATCH_WAIT_TIME = 4;

@implementation LeanplumHelper

static NSString *_lastErrorMessage = nil;

+ (NSString *)lastErrorMessage {
  return _lastErrorMessage;
}

+ (void)setLastErrorMessage:(NSString *)lastErrorMessage {
    NSLog(@"Exception: %@", lastErrorMessage);
    _lastErrorMessage = lastErrorMessage;
}

static id _leanplumClassMock = nil;

+ (id)leanplumClassMock {
  return _leanplumClassMock;
}

+ (void)setLeanplumClassMock:(id)leanplumClassMock {
    _leanplumClassMock = leanplumClassMock;
}

static BOOL swizzled = NO;

+ (BOOL)swizzled {
    return swizzled;
}

+ (void)setup_method_swizzling {
    if (!swizzled) {
        [LPRequestFactory swizzle_methods];
        [LPRequest swizzle_methods];
        [LPRequestSender swizzle_methods];
        [Leanplum_Reachability swizzle_methods];
        [LPNetworkOperation swizzle_methods];
        swizzled = YES;
    }
}

+ (void)setup_development_test {
    [Leanplum setLogLevel:LPLogLevelDebug];
    [Leanplum setAppId:APPLICATION_ID withDevelopmentKey:DEVELOPMENT_KEY];
    
    if (@available(iOS 13.0, *)) {
        [[MigrationManager shared] setMigrationState:MigrationStateLeanplum];
    } else {
        [MigrationManagerUtil setSharedMigrateState:MigrationStateLeanplum];
    }
}

+ (void)setup_production_test {
    [Leanplum setLogLevel:LPLogLevelDebug];
    [Leanplum setAppId:APPLICATION_ID withProductionKey:PRODUCTION_KEY];
    
    if (@available(iOS 13.0, *)) {
        [[MigrationManager shared] setMigrationState:MigrationStateLeanplum];
    } else {
        [MigrationManagerUtil setSharedMigrateState:MigrationStateLeanplum];
    }
}

+ (BOOL)start_development_test {
    [LeanplumHelper setup_development_test];
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    id startStub = [HTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest * _Nonnull request) {
        return [request.URL.host isEqualToString:API_HOST];
    } withStubResponse:^HTTPStubsResponse * _Nonnull(NSURLRequest * _Nonnull request) {
        NSString *response_file = OHPathForFile(@"simple_start_response.json", self.class);
        return [HTTPStubsResponse responseWithFileAtPath:response_file statusCode:200
                                                   headers:@{@"Content-Type":@"application/json"}];
    }];
    
    [Leanplum startWithResponseHandler:^(BOOL success) {
        [HTTPStubs removeStub:startStub];
        if (success) {
            dispatch_semaphore_signal(semaphore);
        } else {
            NSLog(@"Start Development Test failed.");
        }
    }];
    long timedOut = dispatch_semaphore_wait(semaphore, [LeanplumHelper default_dispatch_time]);
    return timedOut == 0;
}

+ (BOOL)start_production_test {
    [LeanplumHelper setup_production_test];
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    id startStub = [HTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest * _Nonnull request) {
        return [request.URL.host isEqualToString:API_HOST];
    } withStubResponse:^HTTPStubsResponse * _Nonnull(NSURLRequest * _Nonnull request) {
        NSString *response_file = OHPathForFile(@"simple_start_response.json", self.class);
        return [HTTPStubsResponse responseWithFileAtPath:response_file statusCode:200
                                                   headers:@{@"Content-Type":@"application/json"}];
    }];
    
    [Leanplum startWithResponseHandler:^(BOOL success) {
        [HTTPStubs removeStub:startStub];
        if (success) {
            dispatch_semaphore_signal(semaphore);
        }
    }];
    long timedOut = dispatch_semaphore_wait(semaphore, [LeanplumHelper default_dispatch_time]);
    return timedOut == 0;
}

+ (void)clean_up {
    [Leanplum reset];
    [[LPVarCache sharedCache] reset];
    [[LPVarCache sharedCache] initialize];
    [LPActionTriggerManager reset];
    [[Leanplum user] setDeviceId:nil];
    [[Leanplum user] setUserId:nil];
    
    [[LPConstantsState sharedState] setIsDevelopmentModeEnabled:NO];
    [[LPConstantsState sharedState] setIsInPermanentFailureState:NO];
    
    // Reset values directly
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    [ApiConfig shared].appId = nil;
    [ApiConfig shared].accessKey = nil;
#pragma clang diagnostic pop
    
    [LPRequest reset];
    [LPRequestSender reset];
    [LeanplumHelper reset_user_defaults];
    [[LPOperationQueue serialQueue] cancelAllOperations];
    [[LPOperationQueue serialQueue] waitUntilAllOperationsAreFinished];
}

+ (dispatch_time_t)default_dispatch_time {
    return dispatch_time(DISPATCH_TIME_NOW, DISPATCH_WAIT_TIME *NSEC_PER_SEC);
}

+ (NSString *)retrieve_string_from_file:(NSString *)file ofType:(NSString *)type {
#if SWIFTPM_MODULE_BUNDLE
    NSBundle *bundle = SWIFTPM_MODULE_BUNDLE;
#else
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
#endif
    NSString *path = [bundle pathForResource:file ofType:type];
    NSString *content = [NSString stringWithContentsOfFile:path
                                                  encoding:NSUTF8StringEncoding
                                                     error:nil];

    return content;
}

+ (NSData *)retrieve_data_from_file:(NSString *)file ofType:(NSString *)type {
#if SWIFTPM_MODULE_BUNDLE
    NSBundle *bundle = SWIFTPM_MODULE_BUNDLE;
#else
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
#endif
    NSString *path = [bundle pathForResource:file ofType:type];

    return [[NSFileManager defaultManager] contentsAtPath:path];
}

/// resets all user defaults
+ (void)reset_user_defaults {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *dictionary = [defaults dictionaryRepresentation];

    for (id key in dictionary) {
        [defaults removeObjectForKey:key];
    }
}

+ (void)throwError:(NSString *) err
{
    [LeanplumHelper setLastErrorMessage:err];
    @throw([NSException exceptionWithName:err reason:nil userInfo:nil]);
}

+ (void) handleException:(NSException *) ex
{
    [LeanplumHelper setLastErrorMessage:[ex name]];
    @throw(ex);
}

+ (void)mockThrowErrorToThrow
{
    [LeanplumHelper setLeanplumClassMock:OCMClassMock([Leanplum class])];
    [OCMStub(ClassMethod([[LeanplumHelper leanplumClassMock] throwError:[OCMArg any]])) andCall:@selector(throwError:) onObject:self];

    // Cannot mock leanplumInternalError(NSException *e) since it is a function
    // Mocking [LPUtils handleException:e] which is used inside leanplumInternalError first
    id mockLPUtilsClass = OCMClassMock([LPUtils class]);
    [OCMStub(ClassMethod([mockLPUtilsClass handleException:[OCMArg any]])) andCall:@selector(handleException:) onObject:self];
}

+ (void)stopMockThrowErrorToThrow
{
    [[LeanplumHelper leanplumClassMock] stopMocking];
}

+ (void)restore_method_swizzling
{
    [LPRequestSender unswizzle_methods];
    [LPRequestFactory unswizzle_methods];
    
    [LPRequest unswizzle_methods];
    [Leanplum_Reachability unswizzle_methods];
    [LPNetworkOperation unswizzle_methods];
    
    swizzled = NO;
}

@end
