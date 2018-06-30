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

#import "Leanplum.h"
#import "LeanplumInternal.h"
#import "LPRequest.h"
#import "LPRequestManager.h"
#import "LPResponse.h"
#import "Constants.h"
#import "LPFileManager.h"
#import "NSTimer+Blocks.h"
#import "LPKeychainWrapper.h"
#import "LPEventDataManager.h"
#import "LPEventCallbackManager.h"

@interface LPRequestManager()

@property (nonatomic, strong) NSString *appId;
@property (nonatomic, strong) id<LPNetworkEngineProtocol> engine;
@property (nonatomic, strong) NSString *accessKey;
@property (nonatomic, strong) NSMutableDictionary *fileTransferStatus;
@property (nonatomic, assign) int pendingDownloads;
@property (nonatomic, strong) LeanplumVariablesChangedBlock noPendingDownloadsBlock;
@property (nonatomic, strong) NSMutableDictionary *fileUploadSize;
@property (nonatomic, strong) NSMutableDictionary *fileUploadProgress;
@property (nonatomic, strong) NSString *fileUploadProgressString;
@property (nonatomic, strong) NSMutableDictionary *pendingUploads;
@property (nonatomic, assign) NSTimeInterval lastSentTime;
@property (nonatomic, strong) NSDictionary *requestHeaders;

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
    self.fileTransferStatus = [[NSMutableDictionary alloc] init];
    self.fileUploadSize = [NSMutableDictionary dictionary];
    self.fileUploadProgress = [NSMutableDictionary dictionary];
    self.pendingUploads = [NSMutableDictionary dictionary];
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
                                                                httpMethod:@"post" //TODO: Figure out httpMethod for multi request
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
//            NSLog(@"Leanplum: Request %@ timed out", _apiMethod); //TODO: APImethod?
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
                                                                 httpMethod:@"post" // _httpMethod //TODO: figure this out
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
        [self printUploadProgress];
        LP_END_TRY //TODO: figure this out
//        if (_response != nil) {
//            _response(operation, json);
//        }
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
         [self printUploadProgress];
         NSLog(@"Leanplum: %@", err);
         // TODO
//         if (_error != nil) {
//             _error(err);
//         }
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
        [self printUploadProgress];
         LP_END_TRY
     }];

    // Send.
    [self.engine enqueueOperation: op];
}

- (void)sendDataNow:(NSData *)data forKey:(NSString *)key
{
    [self sendDatasNow:@{key: data}];
}

- (void)sendDatasNow:(NSDictionary *)datas
{
//    NSMutableDictionary *dict = [self createArgsDictionary];
//    [self attachApiKeys:dict];
//    id<LPNetworkOperationProtocol> op =
//    [engine operationWithPath:[LPConstantsState sharedState].apiServlet
//                       params:dict
//                   httpMethod:_httpMethod
//                          ssl:[LPConstantsState sharedState].apiSSL
//               timeoutSeconds:60];
//
//    [datas enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
//        [op addData:obj forKey:key];
//    }];
//
//    [op addCompletionHandler:^(id<LPNetworkOperationProtocol> operation, id json) {
//        if (_response != nil) {
//            _response(operation, json);
//        }
//    } errorHandler:^(id<LPNetworkOperationProtocol> operation, NSError *err) {
//        LP_TRY
//        if (_error != nil) {
//            _error(err);
//        }
//        LP_END_TRY
//    }];
//    [engine enqueueOperation: op];
}
//
//- (void)sendFilesNow:(NSArray *)filenames
//{
//    RETURN_IF_TEST_MODE;
//    NSMutableArray *filesToUpload = [NSMutableArray array];
//    for (NSString *filename in filenames) {
//        // Set state.
//        if ([fileTransferStatus[filename] boolValue]) {
//            [filesToUpload addObject:@""];
//        } else {
//            [filesToUpload addObject:filename];
//            fileTransferStatus[filename] = @(YES);
//            NSNumber *size = [[[NSFileManager defaultManager] attributesOfItemAtPath:filename error:nil] objectForKey:NSFileSize];
//            fileUploadSize[filename] = size;
//            fileUploadProgress[filename] = @0.0;
//        }
//    }
//    if (filesToUpload.count == 0) {
//        return;
//    }
//
//    // Create request.
//    NSMutableDictionary *dict = [self createArgsDictionary];
//    dict[LP_PARAM_COUNT] = @(filesToUpload.count);
//    [self attachApiKeys:dict];
//    @synchronized (pendingUploads) {
//        pendingUploads[filesToUpload] = dict;
//    }
//    [self maybeSendNextUpload];
//
//    NSLog(@"Leanplum: Uploading files...");
//}
//
//- (void)downloadFile:(NSString *)path
//{
//    RETURN_IF_TEST_MODE;
//    if ([fileTransferStatus[path] boolValue]) {
//        return;
//    }
//    pendingDownloads++;
//    NSLog(@"Leanplum: Downloading resource %@", path);
//    fileTransferStatus[path] = @(YES);
//    NSMutableDictionary *dict = [self createArgsDictionary];
//    dict[LP_KEY_FILENAME] = path;
//    [self attachApiKeys:dict];
//
//    // Download it directly if the argument is URL.
//    // Otherwise continue with the api request.
//    id<LPNetworkOperationProtocol> op;
//    if ([path hasPrefix:@"http://"] || [path hasPrefix:@"https://"]) {
//        op = [engine operationWithURLString:path];
//    } else {
//        op = [engine operationWithPath:[LPConstantsState sharedState].apiServlet
//                                params:dict
//                            httpMethod:[LPNetworkFactory fileRequestMethod]
//                                   ssl:[LPConstantsState sharedState].apiSSL
//                        timeoutSeconds:[LPConstantsState sharedState]
//                                        .networkTimeoutSecondsForDownloads];
//    }
//
//    [op addCompletionHandler:^(id<LPNetworkOperationProtocol> operation, id json) {
//        LP_TRY
//        [[operation responseData] writeToFile:[LPFileManager fileRelativeToDocuments:path
//                                              createMissingDirectories:YES] atomically:YES];
//        pendingDownloads--;
//        if (_response != nil) {
//            _response(operation, json);
//        }
//        if (pendingDownloads == 0 && noPendingDownloadsBlock) {
//            noPendingDownloadsBlock();
//        }
//        LP_END_TRY
//    } errorHandler:^(id<LPNetworkOperationProtocol> operation, NSError *err) {
//        LP_TRY
//        NSLog(@"Leanplum: %@", err);
//        pendingDownloads--;
//        if (_error != nil) {
//            _error(err);
//        }
//        if (pendingDownloads == 0 && noPendingDownloadsBlock) {
//            noPendingDownloadsBlock();
//        }
//        LP_END_TRY
//    }];
//    [engine enqueueOperation: op];
//}
//
//- (int)numPendingDownloads
//{
//    return pendingDownloads;
//}
//
//- (void)onNoPendingDownloads:(LeanplumVariablesChangedBlock)block
//{
//    noPendingDownloadsBlock = block;
//}
//
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
