//
//  LPFileUploadManager.m
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

#import "LPFileUploadDownloadManager.h"
#import "LeanplumInternal.h"
<<<<<<< HEAD
#import "LeanplumRequest.h"
#import "LPFileUploadDownloadManager.h"
=======
#import "LPRequest.h"
#import "LPRequestManager.h"
>>>>>>> refactor request class
#import "LPResponse.h"
#import "LPFileManager.h"

@interface LPFileUploadDownloadManager()

<<<<<<< HEAD
@implementation LPFileUploadDownloadManager
=======
@property (nonatomic, strong) NSMutableDictionary *fileTransferStatus;
>>>>>>> refactor request class

@property (nonatomic, strong) NSMutableDictionary *fileUploadSize;
@property (nonatomic, strong) NSMutableDictionary *fileUploadProgress;
@property (nonatomic, strong) NSString *fileUploadProgressString;
@property (nonatomic, strong) NSMutableDictionary *pendingUploads;
@property (nonatomic, strong) NSDictionary *requestHeaders;

@property (nonatomic, assign) int pendingDownloads;
@property (nonatomic, strong) LeanplumVariablesChangedBlock noPendingDownloadsBlock;

@property (nonatomic, strong) id<LPNetworkEngineProtocol> engine;

@end


@implementation LPFileUploadDownloadManager

+ (instancetype)sharedManager {
    static LPFileUploadDownloadManager *sharedManager = nil;
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
        _fileTransferStatus = [[NSMutableDictionary alloc] init];
        _fileUploadSize = [NSMutableDictionary dictionary];
        _fileUploadProgress = [NSMutableDictionary dictionary];
        _pendingUploads = [NSMutableDictionary dictionary];
        
<<<<<<< HEAD
        if (engine == nil) {
            if (!_requestHheaders) {
                _requestHheaders = [LPFileUploadDownloadManager createHeaders];
=======
        if (_engine == nil) {
            if (!_requestHeaders) {
                _requestHeaders = [[LPRequestManager sharedManager] createHeaders];
>>>>>>> refactor request class
            }
            _engine = [LPNetworkFactory engineWithHostName:[LPConstantsState sharedState].apiHostName
                                        customHeaderFields:_requestHeaders];
        }

    }
    return self;
}

- (void)sendFilesNow:(NSArray *)filenames fileData:(NSArray *)fileData
{
    RETURN_IF_TEST_MODE;
    NSMutableArray *filesToUpload = [NSMutableArray array];
    for (NSString *filename in filenames) {
        // Set state.
        if ([self.fileTransferStatus[filename] boolValue]) {
            [filesToUpload addObject:@""];
        } else {
            [filesToUpload addObject:filename];
            self.fileTransferStatus[filename] = @(YES);
            NSNumber *size = [[[NSFileManager defaultManager] attributesOfItemAtPath:filename error:nil] objectForKey:NSFileSize];
            self.fileUploadSize[filename] = size;
            self.fileUploadProgress[filename] = @0.0;
        }
    }
    if (filesToUpload.count == 0) {
        return;
    }
<<<<<<< HEAD
        
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
        
        [LPFileUploadDownloadManager generateUUID];
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
            [[LPFileUploadDownloadManager sendNowQueue] cancelAllOperations];
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
            [[LPFileUploadDownloadManager sendNowQueue] cancelAllOperations];
            LP_END_TRY
        }
        LP_END_TRY
    };
    
    // Send. operationBlock will run synchronously.
    // Adding to OperationQueue puts it in the background.
    if (async) {
        [requestOperation addExecutionBlock:operationBlock];
        [[LPFileUploadDownloadManager sendNowQueue] addOperation:requestOperation];
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
            uuid = [LPFileUploadDownloadManager generateUUID];
        }
        
        @synchronized ([LPEventCallbackManager eventCallbackMap]) {
            NSMutableDictionary *args = [self createArgsDictionary];
            args[LP_PARAM_UUID] = uuid;
            [LPEventDataManager addEvent:args];
            
            [LPEventCallbackManager addEventCallbackAt:count
                                             onSuccess:_response
                                               onError:_error];
        }
=======

    LPRequest *request = [LPRequest post:LP_METHOD_UPLOAD_FILE
                                  params:@{LP_PARAM_DATA: [LPJSON stringFromJSON:fileData]}];
    NSMutableDictionary *dict = [[LPRequestManager sharedManager] createArgsDictionaryForRequest:request];
    dict[LP_PARAM_COUNT] = @(filesToUpload.count);
    [[LPRequestManager sharedManager] attachApiKeys:dict];
    @synchronized (self.pendingUploads) {
        self.pendingUploads[filesToUpload] = dict;
>>>>>>> refactor request class
    }
    [self maybeSendNextUpload];

    NSLog(@"Leanplum: Uploading files...");
}

- (void)printUploadProgress
{
    NSInteger totalFiles = [self.fileUploadSize count];
    int sentFiles = 0;
    int totalBytes = 0;
    int sentBytes = 0;
    for (NSString *filename in [self.fileUploadSize allKeys]) {
        int fileSize = [self.fileUploadSize[filename] intValue];
        double fileProgress = [self.fileUploadProgress[filename] doubleValue];
        if (fileProgress == 1) {
            sentFiles++;
        }
        sentBytes += (int)(fileSize * fileProgress);
        totalBytes += fileSize;
    }
    NSString *progressString = [NSString stringWithFormat:@"Uploading resources. %d/%ld files completed; %@/%@ transferred.",
                                sentFiles, (long) totalFiles,
                                [self getSizeAsString:sentBytes], [self getSizeAsString:totalBytes]];
    if (![self.fileUploadProgressString isEqualToString:progressString]) {
        self.fileUploadProgressString = progressString;
        NSLog(@"Leanplum: %@", progressString);
    }
}

- (void)maybeSendNextUpload
{
    NSMutableArray *filesToUpload;
    NSMutableDictionary *dict;
    NSString *url;
    @synchronized (self.pendingUploads) {
        for (NSMutableArray *item in self.pendingUploads) {
            filesToUpload = item;
            dict = self.pendingUploads[item];
            break;
        }
        if (dict) {
            if (!self.uploadUrl) {
                return;
            }
            url = self.uploadUrl;
            self.uploadUrl = nil;
            [self.pendingUploads removeObjectForKey:filesToUpload];
        }
    }
    if (dict == nil) {
        return;
    }
    id<LPNetworkOperationProtocol> op = [self.engine operationWithURLString:url
                                                                params:dict
                                                                 httpMethod:@"POST"
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
                self.fileUploadProgress[filename] = @(1.0);
            }
        }
<<<<<<< HEAD
        [LPFileUploadDownloadManager printUploadProgress];
=======
        [self printUploadProgress];
>>>>>>> refactor request class
        LP_END_TRY
        LP_TRY
        @synchronized (self.pendingUploads) {
            self.uploadUrl = [[LPResponse getLastResponse:json]
                         objectForKey:LP_KEY_UPLOAD_URL];
        }
        [self maybeSendNextUpload];
        LP_END_TRY
     } errorHandler:^(id<LPNetworkOperationProtocol> operation, NSError *err) {
         LP_TRY
         for (NSString *filename in filesToUpload) {
             if (filename.length) {
                 [self.fileUploadProgress setObject:@(1.0) forKey:filename];
             }
         }
<<<<<<< HEAD
         [LPFileUploadDownloadManager printUploadProgress];
=======
         [self printUploadProgress];
>>>>>>> refactor request class
         NSLog(@"Leanplum: %@", err);
         [self maybeSendNextUpload];
         LP_END_TRY
     }];
    [op onUploadProgressChanged:^(double progress) {
         LP_TRY
         for (NSString *filename in filesToUpload) {
             if (filename.length) {
                 [self.fileUploadProgress setObject:@(MIN(progress, 1.0)) forKey:filename];
             }
         }
<<<<<<< HEAD
         [LPFileUploadDownloadManager printUploadProgress];
=======
        [self printUploadProgress];
>>>>>>> refactor request class
         LP_END_TRY
     }];

    // Send.
    [self.engine enqueueOperation: op];
}

- (NSString *)getSizeAsString:(int)size
{
    if (size < (1 << 10)) {
        return [NSString stringWithFormat:@"%d B", size];
    } else if (size < (1 << 20)) {
        return [NSString stringWithFormat:@"%d KB", (size >> 10)];
    } else {
        return [NSString stringWithFormat:@"%d MB", (size >> 20)];
    }
}

- (void)downloadFile:(NSString *)path onResponse:(LPNetworkResponseBlock)responseBlock onError:(LPNetworkErrorBlock)errorBlock
{
    RETURN_IF_TEST_MODE;
    if ([self.fileTransferStatus[path] boolValue]) {
        return;
    }
    self.pendingDownloads++;
    NSLog(@"Leanplum: Downloading resource %@", path);
    self.fileTransferStatus[path] = @(YES);
    LPRequest *request = [LPRequest get:LP_METHOD_DOWNLOAD_FILE params:nil];
    NSMutableDictionary *dict = [[LPRequestManager sharedManager] createArgsDictionaryForRequest:request];
    dict[LP_KEY_FILENAME] = path;
    [[LPRequestManager sharedManager] attachApiKeys:dict];

    // Download it directly if the argument is URL.
    // Otherwise continue with the api request.
    id<LPNetworkOperationProtocol> op;
    if ([path hasPrefix:@"http://"] || [path hasPrefix:@"https://"]) {
        op = [self.engine operationWithURLString:path];
    } else {
        op = [self.engine operationWithPath:[LPConstantsState sharedState].apiServlet
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
        self.pendingDownloads--;
        if (responseBlock != nil) {
            responseBlock(operation, json);
        }
        if (self.pendingDownloads == 0 && self.noPendingDownloadsBlock) {
            self.noPendingDownloadsBlock();
        }
        LP_END_TRY
    } errorHandler:^(id<LPNetworkOperationProtocol> operation, NSError *err) {
        LP_TRY
        NSLog(@"Leanplum: %@", err);
        self.pendingDownloads--;
        if (errorBlock != nil) {
            errorBlock(err);
        }
        if (self.pendingDownloads == 0 && self.noPendingDownloadsBlock) {
            self.noPendingDownloadsBlock();
        }
        LP_END_TRY
    }];
    [self.engine enqueueOperation: op];
}

- (int)numPendingDownloads
{
    return _pendingDownloads;
}

- (void)onNoPendingDownloads:(LeanplumVariablesChangedBlock)noPendingDownloadsBlock
{
    self.noPendingDownloadsBlock = noPendingDownloadsBlock;
}


@end