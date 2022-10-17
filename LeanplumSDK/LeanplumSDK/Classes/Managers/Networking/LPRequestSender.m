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
#import "LPOperationQueue.h"
#import "LPNetworkConstants.h"
#import "LPRequestSenderTimer.h"
#import "LPRequestBatchFactory.h"
#import <Leanplum/Leanplum-Swift.h>

@interface LPRequestSender()

@property (nonatomic, strong) id<LPNetworkEngineProtocol> engine;
@property (nonatomic, strong) NSDictionary *requestHeaders;

@property (nonatomic, strong) NSTimer *uiTimeoutTimer;
@property (nonatomic, assign) BOOL didUiTimeout;

@property (nonatomic, strong) LPCountAggregator *countAggregator;

- (BOOL)updateApiConfig:(id)json;

@end


@implementation LPRequestSender

+ (instancetype)sharedInstance {
    static LPRequestSender *sharedSender = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedSender = [[self alloc] init];
    });
    return sharedSender;
}

- (id)init
{
    self = [super init];
    if (self) {
        [self initialize];
    }
    return self;
}

- (void)initialize
{
    if (_engine == nil) {
        if (!_requestHeaders) {
            _requestHeaders = [LPNetworkEngine createHeaders];
        }
        _engine = [LPNetworkFactory engineWithCustomHeaderFields:_requestHeaders];
    }
    [[LPRequestSenderTimer sharedInstance] start];
    _countAggregator = [LPCountAggregator sharedAggregator];
}

- (void)send:(LPRequest *)request
{
    if (![[MigrationManager shared] useLeanplum])
        return;
    
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
    if (![ApiConfig shared].appId) {
        LPLog(LPError, @"Cannot send request. appId is not set");
        return false;
    }
    
    if (![ApiConfig shared].appId) {
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
    
    if (![[MigrationManager shared] useLeanplum])
        return;
    
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
            
            NSString *uuid = [self uuid];
            NSInteger count = [LPEventDataManager count];
            if (count % LP_MAX_EVENTS_PER_API_CALL == 0) {
                uuid = [[NSUUID UUID] UUIDString];
                [self setUuid:uuid];
            }

            NSMutableDictionary *args = [request createArgsDictionary];
            args[LP_PARAM_UUID] = uuid;
            
            if ([[MigrationManager shared] useCleverTap]) {
                args[MigrationManager.lpCleverTapRequestArg] = @YES;
            }
            
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
    [ApiConfig attachApiKeysWithDict:dict];
    id<LPNetworkOperationProtocol> op =
    [self.engine operationWithHost:[ApiConfig shared].apiHostName
                              path:[ApiConfig shared].apiPath
                            params:dict
                        httpMethod:@"POST"
                               ssl:[ApiConfig shared].apiSSL
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

        // Update UUID
        [self setUuid:[[NSUUID UUID] UUIDString]];
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
        [ApiConfig attachApiKeysWithDict:multiRequestArgs];
        int timeout = constants.networkTimeoutSeconds;

        NSTimeInterval uiTimeoutInterval = timeout;
        timeout = 5 * timeout; // let slow operations complete

        dispatch_async(dispatch_get_main_queue(), ^{
            self.uiTimeoutTimer = [NSTimer scheduledTimerWithTimeInterval:uiTimeoutInterval target:self selector:@selector(uiDidTimeout) userInfo:nil repeats:NO];
        });
        self.didUiTimeout = NO;

        id<LPNetworkOperationProtocol> op = [self.engine operationWithHost:[ApiConfig shared].apiHostName
                                                                      path:[ApiConfig shared].apiPath
                                                                    params:multiRequestArgs
                                                                httpMethod:@"POST"
                                                                       ssl:[ApiConfig shared].apiSSL
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
            
            if ([self updateApiConfig:json]) {
                // Retry the same request on the new endpoint
                [self sendRequests];
                dispatch_semaphore_signal(semaphore);
                return;
            }
            
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
            
            [[MigrationManager shared] handleMigrateStateWithMultiApiResponse:json];
            
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
                || httpStatusCode == 429
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
            LP_END_TRY
        }
        LP_END_TRY
    };

    [requestOperation addExecutionBlock:operationBlock];
    [[LPOperationQueue serialQueue] addOperation:requestOperation];
}

- (BOOL)updateApiConfig:(id)json {
    if ([json isKindOfClass:NSDictionary.class]) {
        for (NSUInteger i = 0; i < [LPResponse numResponsesInDictionary:json]; i++) {
            NSDictionary *response = [LPResponse getResponseAt:i fromDictionary:json];
            if ([LPResponse isResponseSuccess:response]) {
                continue;
            }
            
            NSString *apiHost = [response objectForKey:LP_PARAM_API_HOST];
            NSString *apiPath = [response objectForKey:LP_PARAM_API_PATH];
            NSString *devServerHost = [response objectForKey:LP_PARAM_DEV_SERVER_HOST];
            if (apiHost || apiPath || devServerHost) {
                // Prevent setting the same API config, prevent request retry loop
                BOOL updateSettings = NO;
                if (apiHost &&
                    ![apiHost isEqualToString:[ApiConfig shared].apiHostName]) {
                    updateSettings = YES;
                } else if (apiPath &&
                           ![apiPath isEqualToString:[ApiConfig shared].apiPath]) {
                    updateSettings = YES;
                } else if (devServerHost &&
                           ![devServerHost isEqualToString:[ApiConfig shared].socketHost]) {
                    updateSettings = YES;
                }
                
                if (updateSettings) {
                    apiHost = apiHost ? apiHost : [ApiConfig shared].apiHostName;
                    apiPath = apiPath ? apiPath : [ApiConfig shared].apiPath;
                    [Leanplum setApiHostName:apiHost withPath:apiPath usingSsl:[ApiConfig shared].apiSSL];
                    
                    devServerHost = devServerHost ? devServerHost : [ApiConfig shared].socketHost;
                    [Leanplum setSocketHostName:devServerHost withPortNumber:(int)[ApiConfig shared].socketPort];
                    return YES;
                } else {
                    return NO;
                }
            }
        }
    }
    return NO;
}

- (void)uiDidTimeout {
    self.didUiTimeout = YES;
    [self.uiTimeoutTimer invalidate];
    self.uiTimeoutTimer = nil;
    // Invoke errors on all requests.
    NSError *error = [NSError errorWithDomain:@"leanplum" code:-1001 userInfo:[NSDictionary dictionaryWithObject:@"Request timed out" forKey:NSLocalizedDescriptionKey]];
    [LPEventCallbackManager invokeErrorCallbacksWithError:error];
}

@end
