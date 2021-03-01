//
//  LPRequestSender.m
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

#import "LPRequestSender.h"
#import "LeanplumInternal.h"
#import "LPCountAggregator.h"
#import "LPRequest.h"
#import "LPResponse.h"
#import "LPKeychainWrapper.h"
#import "LPEventDataManager.h"
#import "LPEventCallbackManager.h"
#import "LPAPIConfig.h"
#import "LPOperationQueue.h"
#import "LPNetworkConstants.h"
#import "LPRequestSenderTimer.h"
#import "LPRequestBatchFactory.h"
#import "LPRequestUUIDHelper.h"

@interface LPRequestSender()

@property (nonatomic, strong) id<LPNetworkEngineProtocol> engine;
@property (nonatomic, strong) NSDictionary *requestHeaders;

@property (nonatomic, strong) NSTimer *uiTimeoutTimer;
@property (nonatomic, assign) BOOL didUiTimeout;

@property (nonatomic, strong) LPCountAggregator *countAggregator;

@end


@implementation LPRequestSender

+ (instancetype)sharedInstance {
    static LPRequestSender *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] init];
    });
    return sharedManager;
}

- (id)init
{
    self = [super init];
    if (self) {
        if (_engine == nil) {
            if (!_requestHeaders) {
                _requestHeaders = [LPNetworkEngine createHeaders];
            }
            _engine = [LPNetworkFactory engineWithHostName:[LPConstantsState sharedState].apiHostName
                                        customHeaderFields:_requestHeaders];
        }
        [[LPRequestSenderTimer sharedInstance] start];
        _countAggregator = [LPCountAggregator sharedAggregator];
    }
    return self;
}

- (void)send:(LPRequest *)request
{
    [self saveRequest:request];
    if ([LPConstantsState sharedState].isDevelopmentModeEnabled || request.requestType == Immediate) {
        if ([self validateConfigFor:request]) {
            if (request.datas != nil) {
                [self sendNow:request withDatas:request.datas];
            } else {
                [self sendNow:request];
            }
        }
    }
}

- (BOOL)validateConfigFor:(LPRequest *)request
{
    if (![LPAPIConfig sharedConfig].appId) {
        LPLog(LPError, @"Cannot send request. appId is not set");
        return false;
    }
    
    if (![LPAPIConfig sharedConfig].accessKey) {
        LPLog(LPError, @"Cannot send request. accessKey is not set");
        return false;
    }
    
    if (![[Leanplum_Reachability reachabilityForInternetConnection] isReachable])
    {
        LPLog(LPError, @"Device is offline, will try sending requests again later.");
        if (request.errorBlock) {
            request.errorBlock([NSError errorWithDomain:@"Leanplum" code:1
                                               userInfo:@{NSLocalizedDescriptionKey: @"Device is offline"}]);
        }

        return false;
    }
    
    return true;
}

- (void)sendNow:(LPRequest *)request
{
    RETURN_IF_TEST_MODE;

    [self sendRequests];
    
    [self.countAggregator incrementCount:@"send_now_lp"];
}

- (void)saveRequest:(LPRequest *)request
{
    RETURN_IF_TEST_MODE;
    if (!request.sent) {
        request.sent = YES;
        
        NSBlockOperation *saveRequestOperation = [NSBlockOperation new];
        __weak NSBlockOperation *weakOperation = saveRequestOperation;
        
        void (^operationBlock)(void) = ^void() {
            LP_TRY
            if ([weakOperation isCancelled]) {
                return;
            }
            
            NSString *uuid = [LPRequestUUIDHelper loadUUID];
            NSInteger count = [LPEventDataManager count];
            if (!uuid || count % LP_MAX_EVENTS_PER_API_CALL == 0) {
                uuid = [LPRequestUUIDHelper generateUUID];
            }

            NSMutableDictionary *args = [request createArgsDictionary];
            args[LP_PARAM_UUID] = uuid;
            
            [LPEventDataManager addEvent:args];

            [LPEventCallbackManager addEventCallbackAt:count
                                             onSuccess:request.responseBlock
                                               onError:request.errorBlock];
            LP_END_TRY
        };

        [saveRequestOperation addExecutionBlock:operationBlock];
        [[LPOperationQueue serialQueue] addOperation:saveRequestOperation];
    }
    
    [self.countAggregator incrementCount:@"send_eventually_lp"];
}

- (void)sendNow:(LPRequest *)request withDatas:(NSDictionary *)datas
{
    NSMutableDictionary *dict = [request createArgsDictionary];
    [LPNetworkEngine attachApiKeys:dict];
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
    
    [self.countAggregator incrementCount:@"send_now_with_datas_lp"];
}

- (void)sendRequests
{
    NSBlockOperation *requestOperation = [NSBlockOperation new];
    __weak NSBlockOperation *weakOperation = requestOperation;

    void (^operationBlock)(void) = ^void() {
        LP_TRY
        if ([weakOperation isCancelled]) {
            return;
        }

        [LPRequestUUIDHelper generateUUID];
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

        [[LPCountAggregator sharedAggregator] sendAllCounts];
        // Simulate pop all requests.
        LPRequestBatch *batch = [LPRequestBatchFactory createNextBatch];
        if ([batch isEmpty]) {
            return;
        }

        // Set up request operation.
        NSString *requestData = [LPJSON stringFromJSON:@{LP_PARAM_DATA:batch.requestsToSend}];
        NSString *timestamp = [NSString stringWithFormat:@"%f", [[NSDate date] timeIntervalSince1970]];
        LPConstantsState *constants = [LPConstantsState sharedState];
        NSMutableDictionary *multiRequestArgs = [@{
                                                   LP_PARAM_DATA: requestData,
                                                   LP_PARAM_SDK_VERSION: constants.sdkVersion,
                                                   LP_PARAM_CLIENT: constants.client,
                                                   LP_PARAM_ACTION: LP_API_METHOD_MULTI,
                                                   LP_PARAM_TIME: timestamp
                                                   } mutableCopy];
        [LPNetworkEngine attachApiKeys:multiRequestArgs];
        int timeout = constants.networkTimeoutSeconds;

        NSTimeInterval uiTimeoutInterval = timeout;
        timeout = 5 * timeout; // let slow operations complete

        dispatch_async(dispatch_get_main_queue(), ^{
            self.uiTimeoutTimer = [NSTimer scheduledTimerWithTimeInterval:uiTimeoutInterval target:self selector:@selector(uiDidTimeout) userInfo:nil repeats:NO];
        });
        self.didUiTimeout = NO;

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

            [self.uiTimeoutTimer invalidate];
            self.uiTimeoutTimer = nil;

            // Delete events on success.
            [LPRequestBatchFactory deleteFinishedBatch:batch];

            // Send another request if the last request had maximum events per api call.
            if ([batch isFull]) {
                [self sendRequests];
            }

            if (!self.didUiTimeout) {
                [LPEventCallbackManager invokeSuccessCallbacksOnResponses:json
                                                                 requests:batch.requestsToSend
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
                LPLog(LPError, [err localizedDescription]);
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
                    LPLog(LPError, errorMessage);
                } else {
                    LPLog(LPError, [err localizedDescription]);
                }

                // Delete on permanant error state.
                [LPRequestBatchFactory deleteFinishedBatch:batch];
            }

            // Invoke errors on all requests.
            [LPEventCallbackManager invokeErrorCallbacksWithError:err];
            [[LPOperationQueue serialQueue] cancelAllOperations];
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
            LPLog(LPInfo, @"Multi Request timed out");
            [op cancel];
            NSError *error = [NSError errorWithDomain:@"Leanplum" code:1
                                             userInfo:@{NSLocalizedDescriptionKey: @"Request timed out"}];
            [LPEventCallbackManager invokeErrorCallbacksWithError:error];
            [[LPOperationQueue serialQueue] cancelAllOperations];
            LP_END_TRY
        }
        LP_END_TRY
    };

    [requestOperation addExecutionBlock:operationBlock];
    [[LPOperationQueue serialQueue] addOperation:requestOperation];
}

-(void)uiDidTimeout {
    self.didUiTimeout = YES;
    [self.uiTimeoutTimer invalidate];
    self.uiTimeoutTimer = nil;
    // Invoke errors on all requests.
    NSError *error = [NSError errorWithDomain:@"leanplum" code:-1001 userInfo:[NSDictionary dictionaryWithObject:@"Request timed out" forKey:NSLocalizedDescriptionKey]];
    [LPEventCallbackManager invokeErrorCallbacksWithError:error];
}

@end
