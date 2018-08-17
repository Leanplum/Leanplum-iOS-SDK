//
//  LPRequest.h
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

#import "LeanplumInternal.h"
<<<<<<< HEAD
#import "LeanplumRequest.h"
#import "LPRequest.h"
#import "LPResponse.h"
#import "Constants.h"
#import "LPFileManager.h"
#import "NSTimer+Blocks.h"
#import "LPKeychainWrapper.h"
#import "LPEventDataManager.h"
#import "LPEventCallbackManager.h"
=======
#import "LPRequest.h"
>>>>>>> refactor request class

@interface LPRequest()

<<<<<<< HEAD
@implementation LPRequest
=======
@property (nonatomic, strong) NSString *httpMethod;
>>>>>>> refactor request class

@end


@implementation LPRequest

- (id)initWithHttpMethod:(NSString *)httpMethod
               apiMethod:(NSString *)apiMethod
                  params:(NSDictionary *)params {
    self = [super init];
    if (self) {
        _httpMethod = httpMethod;
        _apiMethod = apiMethod;
        _params = params;
<<<<<<< HEAD
        
        if (engine == nil) {
            if (!_requestHheaders) {
                _requestHheaders = [LPRequest createHeaders];
            }
            engine = [LPNetworkFactory engineWithHostName:[LPConstantsState sharedState].apiHostName
                                       customHeaderFields:_requestHheaders];
        }
=======
>>>>>>> refactor request class
    }
    return self;
}

+ (LPRequest *)get:(NSString *)apiMethod params:(NSDictionary *)params
{
    LPLogType level = [apiMethod isEqualToString:LP_METHOD_LOG] ? LPDebug : LPVerbose;
    LPLog(level, @"Will call API method %@ with arguments %@", apiMethod, params);
    return [[LPRequest alloc] initWithHttpMethod:@"GET" apiMethod:apiMethod params:params];
}

+ (LPRequest *)post:(NSString *)apiMethod params:(NSDictionary *)params
{
    LPLogType level = [apiMethod isEqualToString:LP_METHOD_LOG] ? LPDebug : LPVerbose;
    LPLog(level, @"Will call API method %@ with arguments %@", apiMethod, params);
    return [[LPRequest alloc] initWithHttpMethod:@"POST" apiMethod:apiMethod params:params];
}

- (void)onResponse:(LPNetworkResponseBlock)responseBlock
{
    self.responseBlock = responseBlock;
}

- (void)onError:(LPNetworkErrorBlock)errorBlock
{
<<<<<<< HEAD
    RETURN_IF_TEST_MODE;

    if (!appId) {
        NSLog(@"Leanplum: Cannot send request. appId is not set");
        return;
    }
    if (!accessKey) {
        NSLog(@"Leanplum: Cannot send request. accessKey is not set");
        return;
    }
        
    [self sendEventually];
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
        
        [LPRequest generateUUID];
        lastSentTime = [NSDate timeIntervalSinceReferenceDate];
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
        id<LPNetworkOperationProtocol> op = [engine operationWithPath:constants.apiServlet
                                                               params:multiRequestArgs
                                                           httpMethod:_httpMethod
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
            [[LPRequest sendNowQueue] cancelAllOperations];
            dispatch_semaphore_signal(semaphore);
            LP_END_TRY
        }];
        
        // Execute synchronously. Don't block for more than 'timeout' seconds.
        [engine enqueueOperation:op];
        dispatch_time_t dispatchTimeout = dispatch_time(DISPATCH_TIME_NOW, timeout*NSEC_PER_SEC);
        long status = dispatch_semaphore_wait(semaphore, dispatchTimeout);
        
        // Request timed out.
        if (status != 0) {
            LP_TRY
            NSLog(@"Leanplum: Request %@ timed out", _apiMethod);
            [op cancel];
            NSError *error = [NSError errorWithDomain:@"Leanplum" code:1
                                             userInfo:@{NSLocalizedDescriptionKey: @"Request timed out"}];
            [LPEventCallbackManager invokeErrorCallbacksWithError:error];
            [[LPRequest sendNowQueue] cancelAllOperations];
            LP_END_TRY
        }
        LP_END_TRY
    };
    
    // Send. operationBlock will run synchronously.
    // Adding to OperationQueue puts it in the background.
    if (async) {
        [requestOperation addExecutionBlock:operationBlock];
        [[LPRequest sendNowQueue] addOperation:requestOperation];
    } else {
        operationBlock();
    }
}

- (void)sendNow
{
    [self sendNow:YES];
}

- (void)sendNowSync
{
    [self sendNow:NO];
}

- (void)sendEventually
{
    RETURN_IF_TEST_MODE;
    if (!_sent) {
        _sent = YES;
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        NSString *uuid = [userDefaults objectForKey:LEANPLUM_DEFAULTS_UUID_KEY];
        NSInteger count = [LPEventDataManager count];
        if (!uuid || count % MAX_EVENTS_PER_API_CALL == 0) {
            uuid = [LPRequest generateUUID];
        }
        
        @synchronized ([LPEventCallbackManager eventCallbackMap]) {
            NSMutableDictionary *args = [self createArgsDictionary];
            args[LP_PARAM_UUID] = uuid;
            [LPEventDataManager addEvent:args];
            
            [LPEventCallbackManager addEventCallbackAt:count
                                             onSuccess:_response
                                               onError:_error];
        }
    }
}

+ (NSString *)getSizeAsString:(int)size
{
    if (size < (1 << 10)) {
        return [NSString stringWithFormat:@"%d B", size];
    } else if (size < (1 << 20)) {
        return [NSString stringWithFormat:@"%d KB", (size >> 10)];
    } else {
        return [NSString stringWithFormat:@"%d MB", (size >> 20)];
    }
}

+ (void)printUploadProgress
{
    NSInteger totalFiles = [fileUploadSize count];
    int sentFiles = 0;
    int totalBytes = 0;
    int sentBytes = 0;
    for (NSString *filename in [fileUploadSize allKeys]) {
        int fileSize = [fileUploadSize[filename] intValue];
        double fileProgress = [fileUploadProgress[filename] doubleValue];
        if (fileProgress == 1) {
            sentFiles++;
        }
        sentBytes += (int)(fileSize * fileProgress);
        totalBytes += fileSize;
    }
    NSString *progressString = [NSString stringWithFormat:@"Uploading resources. %d/%ld files completed; %@/%@ transferred.",
                                sentFiles, (long) totalFiles,
                                [self getSizeAsString:sentBytes], [self getSizeAsString:totalBytes]];
    if (![fileUploadProgressString isEqualToString:progressString]) {
        fileUploadProgressString = progressString;
        NSLog(@"Leanplum: %@", progressString);
    }
}

- (void)maybeSendNextUpload
{
    NSMutableArray *filesToUpload;
    NSMutableDictionary *dict;
    NSString *url;
    @synchronized (pendingUploads) {
        for (NSMutableArray *item in pendingUploads) {
            filesToUpload = item;
            dict = pendingUploads[item];
            break;
        }
        if (dict) {
            if (!uploadUrl) {
                return;
            }
            url = uploadUrl;
            uploadUrl = nil;
            [pendingUploads removeObjectForKey:filesToUpload];
        }
    }
    if (dict == nil) {
        return;
    }
    id<LPNetworkOperationProtocol> op = [engine operationWithURLString:url
                                                                params:dict
                                                            httpMethod:_httpMethod
                                                        timeoutSeconds:60];
    
    int fileIndex = 0;
    for (NSString *filename in filesToUpload) {
        if (filename.length) {
            [op addFile:filename forKey:[NSString stringWithFormat:LP_PARAM_FILES_PATTERN, fileIndex]];
        }
        fileIndex++;
    }
    
    // Callbacks.
    [op addCompletionHandler:^(id<LPNetworkOperationProtocol> operation, id json) {
        LP_TRY
        for (NSString *filename in filesToUpload) {
            if (filename.length) {
                fileUploadProgress[filename] = @(1.0);
            }
        }
        [LPRequest printUploadProgress];
        LP_END_TRY
        if (_response != nil) {
            _response(operation, json);
        }
        LP_TRY
        @synchronized (pendingUploads) {
            uploadUrl = [[LPResponse getLastResponse:json]
                         objectForKey:LP_KEY_UPLOAD_URL];
        }
        [self maybeSendNextUpload];
        LP_END_TRY
     } errorHandler:^(id<LPNetworkOperationProtocol> operation, NSError *err) {
         LP_TRY
         for (NSString *filename in filesToUpload) {
             if (filename.length) {
                 [fileUploadProgress setObject:@(1.0) forKey:filename];
             }
         }
         [LPRequest printUploadProgress];
         NSLog(@"Leanplum: %@", err);
         if (_error != nil) {
             _error(err);
         }
         [self maybeSendNextUpload];
         LP_END_TRY
     }];
    [op onUploadProgressChanged:^(double progress) {
         LP_TRY
         for (NSString *filename in filesToUpload) {
             if (filename.length) {
                 [fileUploadProgress setObject:@(MIN(progress, 1.0)) forKey:filename];
             }
         }
         [LPRequest printUploadProgress];
         LP_END_TRY
     }];
    
    // Send.
    [engine enqueueOperation: op];
}

- (void)sendDataNow:(NSData *)data forKey:(NSString *)key
{
    [self sendDatasNow:@{key: data}];
}

- (void)sendDatasNow:(NSDictionary *)datas
{
    NSMutableDictionary *dict = [self createArgsDictionary];
    [self attachApiKeys:dict];
    id<LPNetworkOperationProtocol> op =
    [engine operationWithPath:[LPConstantsState sharedState].apiServlet
                       params:dict
                   httpMethod:_httpMethod
                          ssl:[LPConstantsState sharedState].apiSSL
               timeoutSeconds:60];

    [datas enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [op addData:obj forKey:key];
    }];
    
    [op addCompletionHandler:^(id<LPNetworkOperationProtocol> operation, id json) {
        if (_response != nil) {
            _response(operation, json);
        }
    } errorHandler:^(id<LPNetworkOperationProtocol> operation, NSError *err) {
        LP_TRY
        if (_error != nil) {
            _error(err);
        }
        LP_END_TRY
    }];
    [engine enqueueOperation: op];
}

- (void)sendFilesNow:(NSArray *)filenames
{
    RETURN_IF_TEST_MODE;
    NSMutableArray *filesToUpload = [NSMutableArray array];
    for (NSString *filename in filenames) {
        // Set state.
        if ([fileTransferStatus[filename] boolValue]) {
            [filesToUpload addObject:@""];
        } else {
            [filesToUpload addObject:filename];
            fileTransferStatus[filename] = @(YES);
            NSNumber *size = [[[NSFileManager defaultManager] attributesOfItemAtPath:filename error:nil] objectForKey:NSFileSize];
            fileUploadSize[filename] = size;
            fileUploadProgress[filename] = @0.0;
        }
    }
    if (filesToUpload.count == 0) {
        return;
    }

    // Create request.
    NSMutableDictionary *dict = [self createArgsDictionary];
    dict[LP_PARAM_COUNT] = @(filesToUpload.count);
    [self attachApiKeys:dict];
    @synchronized (pendingUploads) {
        pendingUploads[filesToUpload] = dict;
    }
    [self maybeSendNextUpload];
 
    NSLog(@"Leanplum: Uploading files...");
}

- (void)downloadFile:(NSString *)path
{
    RETURN_IF_TEST_MODE;
    if ([fileTransferStatus[path] boolValue]) {
        return;
    }
    pendingDownloads++;
    NSLog(@"Leanplum: Downloading resource %@", path);
    fileTransferStatus[path] = @(YES);
    NSMutableDictionary *dict = [self createArgsDictionary];
    dict[LP_KEY_FILENAME] = path;
    [self attachApiKeys:dict];

    // Download it directly if the argument is URL.
    // Otherwise continue with the api request.
    id<LPNetworkOperationProtocol> op;
    if ([path hasPrefix:@"http://"] || [path hasPrefix:@"https://"]) {
        op = [engine operationWithURLString:path];
    } else {
        op = [engine operationWithPath:[LPConstantsState sharedState].apiServlet
                                params:dict
                            httpMethod:[LPNetworkFactory fileRequestMethod]
                                   ssl:[LPConstantsState sharedState].apiSSL
                        timeoutSeconds:[LPConstantsState sharedState]
                                        .networkTimeoutSecondsForDownloads];
    }

    [op addCompletionHandler:^(id<LPNetworkOperationProtocol> operation, id json) {
        LP_TRY
        [[operation responseData] writeToFile:[LPFileManager fileRelativeToDocuments:path
                                              createMissingDirectories:YES] atomically:YES];
        pendingDownloads--;
        if (_response != nil) {
            _response(operation, json);
        }
        if (pendingDownloads == 0 && noPendingDownloadsBlock) {
            noPendingDownloadsBlock();
        }
        LP_END_TRY
    } errorHandler:^(id<LPNetworkOperationProtocol> operation, NSError *err) {
        LP_TRY
        NSLog(@"Leanplum: %@", err);
        pendingDownloads--;
        if (_error != nil) {
            _error(err);
        }
        if (pendingDownloads == 0 && noPendingDownloadsBlock) {
            noPendingDownloadsBlock();
        }
        LP_END_TRY
    }];
    [engine enqueueOperation: op];
}

+ (int)numPendingDownloads
{
    return pendingDownloads;
}

+ (void)onNoPendingDownloads:(LeanplumVariablesChangedBlock)block
{
    noPendingDownloadsBlock = block;
}

/**
 * Static sendNowQueue with thread protection.
 * Returns an operation queue that manages sendNow to run in order.
 * This is required to prevent from having out of order error in the backend.
 * Also it is very crucial with the uuid logic.
 */
+ (NSOperationQueue *)sendNowQueue
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
=======
    self.errorBlock = errorBlock;
}

@end
>>>>>>> refactor request class
