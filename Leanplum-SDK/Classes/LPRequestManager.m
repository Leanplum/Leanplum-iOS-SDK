//
//  LPRequestManager.m
//  Leanplum
//
//  Created by Mayank Sanganeria on 6/30/18.
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

#import "LPRequestManager.h"
#import "LeanplumInternal.h"
#import "LPRequest.h"
#import "LPResponse.h"
#import "LPKeychainWrapper.h"
#import "LPEventDataManager.h"
#import "LPEventCallbackManager.h"


@interface LPRequestManager()

@property (nonatomic, strong) NSString *appId;
@property (nonatomic, strong) id<LPNetworkEngineProtocol> engine;
@property (nonatomic, strong) NSString *accessKey;
@property (nonatomic, assign) NSTimeInterval lastSentTime;


@end


@implementation LPRequestManager

+ (instancetype)sharedManager {
    static LPRequestManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] init];
        sharedManager.token = nil;
    });
    return sharedManager;
}

- (id)init
{
    self = [super init];
    if (self) {
        if (_engine == nil) {
            if (!_requestHeaders) {
                _requestHeaders = [self createHeaders];
            }
            _engine = [LPNetworkFactory engineWithHostName:[LPConstantsState sharedState].apiHostName
                                       customHeaderFields:_requestHeaders];
        }
    }
    return self;
}

- (void)setAppId:(NSString *)appId withAccessKey:(NSString *)accessKey
{
    self.appId = appId;
    self.accessKey = accessKey;
}

- (void)loadToken
{
    NSError *err;
    NSString *token_ = [LPKeychainWrapper getPasswordForUsername:LP_KEYCHAIN_USERNAME
                                                  andServiceName:LP_KEYCHAIN_SERVICE_NAME
                                                           error:&err];
    if (!token_) {
        return;
    }

    [self setToken:token_];
}

- (void)saveToken
{
    NSError *err;
    [LPKeychainWrapper storeUsername:LP_KEYCHAIN_USERNAME
                         andPassword:[self token]
                      forServiceName:LP_KEYCHAIN_SERVICE_NAME
                      updateExisting:YES
                               error:&err];
}

- (NSDictionary *)createHeaders {
    NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
    NSString *userAgentString = [NSString stringWithFormat:@"%@/%@/%@/%@/%@/%@/%@/%@",
                                 infoDict[(NSString *)kCFBundleNameKey],
                                 infoDict[(NSString *)kCFBundleVersionKey],
                                 self.appId,
                                 LEANPLUM_CLIENT,
                                 LEANPLUM_SDK_VERSION,
                                 [[UIDevice currentDevice] systemName],
                                 [[UIDevice currentDevice] systemVersion],
                                 LEANPLUM_PACKAGE_IDENTIFIER];
    return @{@"User-Agent": userAgentString};
}

+ (NSString *)generateUUID
{
    NSString *uuid = [[NSUUID UUID] UUIDString];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:uuid forKey:LEANPLUM_DEFAULTS_UUID_KEY];
    [userDefaults synchronize];
    return uuid;
}

- (NSMutableDictionary *)createArgsDictionaryForRequest:(LPRequest *)request
{
    LPConstantsState *constants = [LPConstantsState sharedState];
    NSString *timestamp = [NSString stringWithFormat:@"%f", [[NSDate date] timeIntervalSince1970]];
    NSMutableDictionary *args = [@{
                                   LP_PARAM_ACTION: request.apiMethod,
                                   LP_PARAM_DEVICE_ID: self.deviceId ?: @"",
                                   LP_PARAM_USER_ID: self.userId ?: @"",
                                   LP_PARAM_SDK_VERSION: constants.sdkVersion,
                                   LP_PARAM_CLIENT: constants.client,
                                   LP_PARAM_DEV_MODE: @(constants.isDevelopmentModeEnabled),
                                   LP_PARAM_TIME: timestamp,
                                   } mutableCopy];
    if (LPRequestManager.sharedManager.token) {
        args[LP_PARAM_TOKEN] = self.token;
    }
    [args addEntriesFromDictionary:request.params];
    return args;
}

- (void)sendRequest:(LPRequest *)request
{
    [self sendEventuallyRequest:request];
    if ([LPConstantsState sharedState].isDevelopmentModeEnabled) {
        NSTimeInterval currentTime = [NSDate timeIntervalSinceReferenceDate];
        NSTimeInterval delay;
        if (!self.lastSentTime || currentTime - self.lastSentTime > LP_REQUEST_DEVELOPMENT_MAX_DELAY) {
            delay = LP_REQUEST_DEVELOPMENT_MIN_DELAY;
        } else {
            delay = (self.lastSentTime + LP_REQUEST_DEVELOPMENT_MAX_DELAY) - currentTime;
        }
        [self performSelector:@selector(sendIfConnectedRequest:) withObject:request afterDelay:delay];
    }
}

// Wait 1 second for potential other API calls, and then sends the call synchronously
// if no other call has been sent within 1 minute.
- (void)sendIfDelayedRequest:(LPRequest *)request
{
    [self sendEventuallyRequest:request];
    [self performSelector:@selector(sendIfDelayedHelperRequest:)
               withObject:request
               afterDelay:LP_REQUEST_RESUME_DELAY];
}

// Sends the call synchronously if no other call has been sent within 1 minute.
- (void)sendIfDelayedHelperRequest:(LPRequest *)request
{
    LP_TRY
    if ([LPConstantsState sharedState].isDevelopmentModeEnabled) {
        [self sendRequest:request];
    } else {
        NSTimeInterval currentTime = [NSDate timeIntervalSinceReferenceDate];
        if (!self.lastSentTime || currentTime - self.lastSentTime > LP_REQUEST_PRODUCTION_DELAY) {
            [self sendIfConnectedRequest:request];
        }
    }
    LP_END_TRY
}

- (void)sendIfConnectedRequest:(LPRequest *)request
{
    LP_TRY
    [self sendIfConnectedSync:NO request:request];
    LP_END_TRY
}

- (void)sendIfConnectedSync:(BOOL)sync request:(LPRequest *)request
{
    if ([[Leanplum_Reachability reachabilityForInternetConnection] isReachable]) {
        if (sync) {
            [self sendNowSyncRequest:request];
        } else {
            [self sendNowRequest:request];
        }
    } else {
        [self sendEventuallyRequest:request];
        if (request.errorBlock) {
            request.errorBlock([NSError errorWithDomain:@"Leanplum" code:1
                                   userInfo:@{NSLocalizedDescriptionKey: @"Device is offline"}]);
        }
    }
}

- (void)attachApiKeys:(NSMutableDictionary *)dict
{
    dict[LP_PARAM_APP_ID] = self.appId;
    dict[LP_PARAM_CLIENT_KEY] = self.accessKey;
}

- (void)sendNow:(BOOL)async request:(LPRequest *)request
{
    RETURN_IF_TEST_MODE;

    if (!self.appId) {
        NSLog(@"Leanplum: Cannot send request. appId is not set");
        return;
    }
    if (!self.accessKey) {
        NSLog(@"Leanplum: Cannot send request. accessKey is not set");
        return;
    }

    [self sendEventuallyRequest:request];
    [self sendRequests:async];
}

- (void)sendRequests:(BOOL)async
{
    NSBlockOperation *requestOperation = [NSBlockOperation new];
    __weak NSBlockOperation *weakOperation = requestOperation;

    void (^operationBlock)(void) = ^void() {
        LP_TRY
        if ([weakOperation isCancelled]) {
            return;
        }

        [LPRequestManager generateUUID];
        self.lastSentTime = [NSDate timeIntervalSinceReferenceDate];
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

        // Simulate pop all requests.
        NSArray *requestsToSend = [LPEventDataManager eventsWithLimit:MAX_EVENTS_PER_API_CALL];
        if (requestsToSend.count == 0) {
            return;
        }

        // Set up request operation.
        NSString *requestData = [LPJSON stringFromJSON:@{LP_PARAM_DATA:requestsToSend}];
        NSString *timestamp = [NSString stringWithFormat:@"%f", [[NSDate date] timeIntervalSince1970]];
        LPConstantsState *constants = [LPConstantsState sharedState];
        NSMutableDictionary *multiRequestArgs = [@{
                                                   LP_PARAM_DATA: requestData,
                                                   LP_PARAM_SDK_VERSION: constants.sdkVersion,
                                                   LP_PARAM_CLIENT: constants.client,
                                                   LP_PARAM_ACTION: LP_METHOD_MULTI,
                                                   LP_PARAM_TIME: timestamp
                                                   } mutableCopy];
        [self attachApiKeys:multiRequestArgs];
        int timeout = async ? constants.networkTimeoutSeconds : constants.syncNetworkTimeoutSeconds;
        id<LPNetworkOperationProtocol> op = [self.engine operationWithPath:constants.apiServlet
                                                               params:multiRequestArgs
                                                                httpMethod:@"POST"
                                                                  ssl:constants.apiSSL
                                                       timeoutSeconds:timeout];

        // Request callbacks.
        [op addCompletionHandler:^(id<LPNetworkOperationProtocol> operation, id json) {
            LP_TRY
            if ([weakOperation isCancelled]) {
                dispatch_semaphore_signal(semaphore);
                return;
            }

            // We need to lock sendNowCallbackMap so that new event callback won't be triggered
            // right after it gets deleted.
            @synchronized ([LPEventCallbackManager eventCallbackMap]) {
                LP_TRY
                // Delete events on success.
                [LPEventDataManager deleteEventsWithLimit:requestsToSend.count];

                // Send another request if the last request had maximum events per api call.
                if (requestsToSend.count == MAX_EVENTS_PER_API_CALL) {
                    [self sendRequests:async];
                }
                LP_END_TRY

                [LPEventCallbackManager invokeSuccessCallbacksOnResponses:json
                                                                 requests:requestsToSend
                                                                operation:operation];
            }
            dispatch_semaphore_signal(semaphore);
            LP_END_TRY

        } errorHandler:^(id<LPNetworkOperationProtocol> completedOperation, NSError *err) {
            LP_TRY
            if ([weakOperation isCancelled]) {
                dispatch_semaphore_signal(semaphore);
                return;
            }

            // Retry on 500 and other network failures.
            NSInteger httpStatusCode = completedOperation.HTTPStatusCode;
            if (httpStatusCode == 408
                || (httpStatusCode >= 500 && httpStatusCode < 600)
                || err.code == NSURLErrorBadServerResponse
                || err.code == NSURLErrorCannotConnectToHost
                || err.code == NSURLErrorDNSLookupFailed
                || err.code == NSURLErrorNotConnectedToInternet
                || err.code == NSURLErrorTimedOut) {
                NSLog(@"Leanplum: %@", err);
            } else {
                id errorResponse = completedOperation.responseJSON;
                NSString *errorMessage = [LPResponse getResponseError:[LPResponse getLastResponse:errorResponse]];
                if (errorMessage) {
                    if ([errorMessage hasPrefix:@"App not found"]) {
                        errorMessage = @"No app matching the provided app ID was found.";
                        constants.isInPermanentFailureState = YES;
                    } else if ([errorMessage hasPrefix:@"Invalid access key"]) {
                        errorMessage = @"The access key you provided is not valid for this app.";
                        constants.isInPermanentFailureState = YES;
                    } else if ([errorMessage hasPrefix:@"Development mode requested but not permitted"]) {
                        errorMessage = @"A call to [Leanplum setAppIdForDevelopmentMode] with your production key was made, which is not permitted.";
                        constants.isInPermanentFailureState = YES;
                    }
                    NSLog(@"Leanplum: %@", errorMessage);
                } else {
                    NSLog(@"Leanplum: %@", err);
                }

                // Delete on permanant error state.
                [LPEventDataManager deleteEventsWithLimit:requestsToSend.count];
            }

            // Invoke errors on all requests.
            [LPEventCallbackManager invokeErrorCallbacksWithError:err];
            [[self sendNowQueue] cancelAllOperations];
            dispatch_semaphore_signal(semaphore);
            LP_END_TRY
        }];

        // Execute synchronously. Don't block for more than 'timeout' seconds.
        [self.engine enqueueOperation:op];
        dispatch_time_t dispatchTimeout = dispatch_time(DISPATCH_TIME_NOW, timeout*NSEC_PER_SEC);
        long status = dispatch_semaphore_wait(semaphore, dispatchTimeout);

        // Request timed out.
        if (status != 0) {
            LP_TRY
            NSLog(@"Leanplum: Multi Request timed out");
            [op cancel];
            NSError *error = [NSError errorWithDomain:@"Leanplum" code:1
                                             userInfo:@{NSLocalizedDescriptionKey: @"Request timed out"}];
            [LPEventCallbackManager invokeErrorCallbacksWithError:error];
            [[self sendNowQueue] cancelAllOperations];
            LP_END_TRY
        }
        LP_END_TRY
    };

    // Send. operationBlock will run synchronously.
    // Adding to OperationQueue puts it in the background.
    if (async) {
        [requestOperation addExecutionBlock:operationBlock];
        [[self sendNowQueue] addOperation:requestOperation];
    } else {
        operationBlock();
    }
}

- (void)sendNowRequest:(LPRequest *)request
{
    [self sendNow:YES request:request];
}

- (void)sendNowSyncRequest:(LPRequest *)request
{
    [self sendNow:NO request:request];
}

- (void)sendEventuallyRequest:(LPRequest *)request
{
    RETURN_IF_TEST_MODE;
    if (!request.sent) {
        request.sent = YES;
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        NSString *uuid = [userDefaults objectForKey:LEANPLUM_DEFAULTS_UUID_KEY];
        NSInteger count = [LPEventDataManager count];
        if (!uuid || count % MAX_EVENTS_PER_API_CALL == 0) {
            uuid = [LPRequestManager generateUUID];
        }

        @synchronized ([LPEventCallbackManager eventCallbackMap]) {
            NSMutableDictionary *args = [self createArgsDictionaryForRequest:request];
            args[LP_PARAM_UUID] = uuid;
            [LPEventDataManager addEvent:args];

            [LPEventCallbackManager addEventCallbackAt:count
                                             onSuccess:request.responseBlock
                                               onError:request.errorBlock];
        }
    }
}

- (void)sendDataNow:(NSData *)data forKey:(NSString *)key request:(LPRequest *)request
{
    [self sendDatasNow:@{key: data} request:request];
}

- (void)sendDatasNow:(NSDictionary *)datas request:(LPRequest *)request;
{
    NSMutableDictionary *dict = [self createArgsDictionaryForRequest:request];
    [self attachApiKeys:dict];
    id<LPNetworkOperationProtocol> op =
    [self.engine operationWithPath:[LPConstantsState sharedState].apiServlet
                       params:dict
                   httpMethod:@"POST"
                          ssl:[LPConstantsState sharedState].apiSSL
               timeoutSeconds:60];

    [datas enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [op addData:obj forKey:key];
    }];

    [op addCompletionHandler:^(id<LPNetworkOperationProtocol> operation, id json) {
        if (request.responseBlock != nil) {
            request.responseBlock(operation, json);
        }
    } errorHandler:^(id<LPNetworkOperationProtocol> operation, NSError *err) {
        LP_TRY
        if (request.errorBlock != nil) {
            request.errorBlock(err);
        }
        LP_END_TRY
    }];
    [self.engine enqueueOperation: op];
}

/**
 * Static sendNowQueue with thread protection.
 * Returns an operation queue that manages sendNow to run in order.
 * This is required to prevent from having out of order error in the backend.
 * Also it is very crucial with the uuid logic.
 */
- (NSOperationQueue *)sendNowQueue
{
    static NSOperationQueue *_sendNowQueue;
    static dispatch_once_t sendNowQueueToken;
    dispatch_once(&sendNowQueueToken, ^{
        _sendNowQueue = [NSOperationQueue new];
        _sendNowQueue.maxConcurrentOperationCount = 1;
    });
    return _sendNowQueue;
}

@end
