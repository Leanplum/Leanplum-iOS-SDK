//
//  LeanplumRequest.m
//  Leanplum
//
//  Created by Andrew First on 4/30/12.
//  Copyright (c) 2012 Leanplum. All rights reserved.
//

#import "Leanplum.h"
#import "LeanplumInternal.h"
#import "LeanplumRequest.h"
#import "Constants.h"
#import "LPFileManager.h"
#import "NSTimer+Blocks.h"
#import "LPRequestStorage.h"
#import "LPKeychainWrapper.h"

static id<LPNetworkEngineProtocol> engine;
static NSString *appId;
static NSString *accessKey;
static NSString *deviceId;
static NSString *userId;
static NSString *uploadUrl;
static NSMutableDictionary *fileTransferStatus;
static int pendingDownloads;
static LeanplumVariablesChangedBlock noPendingDownloadsBlock;
static NSString *token = nil;
static NSMutableDictionary *fileUploadSize;
static NSMutableDictionary *fileUploadProgress;
static NSString *fileUploadProgressString;
static NSMutableDictionary *pendingUploads;

static NSDictionary *_requestHheaders;

@implementation LeanplumRequest

+ (void)setAppId:(NSString *)appId_ withAccessKey:(NSString *)accessKey_
{
    appId = appId_;
    accessKey = accessKey_;
    fileTransferStatus = [[NSMutableDictionary alloc] init];
    fileUploadSize = [NSMutableDictionary dictionary];
    fileUploadProgress = [NSMutableDictionary dictionary];
    pendingUploads = [NSMutableDictionary dictionary];
}

+ (void)setUserId:(NSString *)userId_
{
    userId = userId_;
}

+ (void)setDeviceId:(NSString *)deviceId_
{
    deviceId = deviceId_;
}

+ (void)setUploadUrl:(NSString *)url_
{
    uploadUrl = url_;
}

+ (NSString *)deviceId
{
    return deviceId;
}

+ (NSString *)userId
{
    return userId;
}

+ (void)setToken:(NSString *)token_
{
    token = token_;
}

+ (NSString *)token
{
    return token;
}

+ (void)loadToken
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

+ (void)saveToken
{
    NSError *err;
    [LPKeychainWrapper storeUsername:LP_KEYCHAIN_USERNAME
                         andPassword:[self token]
                      forServiceName:LP_KEYCHAIN_SERVICE_NAME
                      updateExisting:YES
                               error:&err];
}

+ (NSString *)appId
{
    return appId;
}

- (id)initWithHttpMethod:(NSString *)httpMethod
               apiMethod:(NSString *)apiMethod
                  params:(NSDictionary *)params
{
    self = [super init];
    if (self) {
        _httpMethod = httpMethod;
        _apiMethod = apiMethod;
        _params = params;
        if (engine == nil) {
            if (!_requestHheaders) {
                _requestHheaders = [LeanplumRequest createHeaders];
            }
            engine = [LPNetworkFactory engineWithHostName:[LPConstantsState sharedState].apiHostName
                                       customHeaderFields:_requestHheaders];
        }
    }
    return self;
}

+ (NSDictionary *)createHeaders {
    NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
    NSString *userAgentString = [NSString stringWithFormat:@"%@/%@/%@/%@/%@/%@/%@/%@",
                                 infoDict[(NSString *)kCFBundleNameKey],
                                 infoDict[(NSString *)kCFBundleVersionKey],
                                 appId,
                                 LEANPLUM_CLIENT,
                                 LEANPLUM_SDK_VERSION,
                                 [[UIDevice currentDevice] systemName],
                                 [[UIDevice currentDevice] systemVersion],
                                 LEANPLUM_PACKAGE_IDENTIFIER];
    return @{@"User-Agent": userAgentString};
}

+ (LeanplumRequest *)get:(NSString *)apiMethod params:(NSDictionary *)params
{
    LPLogType level = [apiMethod isEqualToString:LP_METHOD_LOG] ? LPDebug : LPVerbose;
    LPLog(level, @"Will call API method %@ with arguments %@", apiMethod, params);
    return [[LeanplumRequest alloc] initWithHttpMethod:@"GET" apiMethod:apiMethod params:params];
}

+ (LeanplumRequest *)post:(NSString *)apiMethod params:(NSDictionary *)params
{
    LPLogType level = [apiMethod isEqualToString:LP_METHOD_LOG] ? LPDebug : LPVerbose;
    LPLog(level, @"Will call API method %@ with arguments %@", apiMethod, params);
    return [[LeanplumRequest alloc] initWithHttpMethod:@"POST" apiMethod:apiMethod params:params];
}

- (void)onResponse:(LPNetworkResponseBlock)response
{
    _response = [response copy];
}

- (void)onError:(LPNetworkErrorBlock)error
{
    _error = [error copy];
}

- (NSMutableDictionary *)createArgsDictionary
{
    LPConstantsState *constants = [LPConstantsState sharedState];
    NSMutableDictionary *args = [NSMutableDictionary
                                 dictionaryWithObjectsAndKeys:
                                 _apiMethod, LP_PARAM_ACTION,
                                 deviceId ? deviceId : @"", LP_PARAM_DEVICE_ID,
                                 userId ? userId : @"", LP_PARAM_USER_ID,
                                 constants.sdkVersion, LP_PARAM_SDK_VERSION,
                                 constants.client, LP_PARAM_CLIENT,
                                 @(constants.isDevelopmentModeEnabled), LP_PARAM_DEV_MODE,
                                 [NSString stringWithFormat:@"%f", [[NSDate date] timeIntervalSince1970]], LP_PARAM_TIME, nil];
    if (token) {
        args[LP_PARAM_TOKEN] = token;
    }
    [args addEntriesFromDictionary:_params];
    return args;
}

- (void)send
{
    [self sendEventually];
    if ([LPConstantsState sharedState].isDevelopmentModeEnabled) {
        NSTimeInterval currentTime = [NSDate timeIntervalSinceReferenceDate];
        NSTimeInterval delay;
        NSTimeInterval lastSentTime = [LPRequestStorage sharedStorage].lastSentTime;
        if (!lastSentTime || currentTime - lastSentTime > LP_REQUEST_DEVELOPMENT_MAX_DELAY) {
            delay = LP_REQUEST_DEVELOPMENT_MIN_DELAY;
        } else {
            delay = (lastSentTime + LP_REQUEST_DEVELOPMENT_MAX_DELAY) - currentTime;
        }
        [self performSelector:@selector(sendIfConnected) withObject:nil afterDelay:delay];
    }
}

// Wait 1 second for potential other API calls, and then sends the call synchronously
// if no other call has been sent within 1 minute.
- (void)sendIfDelayed
{
    [self sendEventually];
    [self performSelector:@selector(sendIfDelayedHelper)
               withObject:nil
               afterDelay:LP_REQUEST_RESUME_DELAY];
}

// Sends the call synchronously if no other call has been sent within 1 minute.
- (void)sendIfDelayedHelper
{
    LP_TRY
    if ([LPConstantsState sharedState].isDevelopmentModeEnabled) {
        [self send];
    } else {
        NSTimeInterval currentTime = [NSDate timeIntervalSinceReferenceDate];
        NSTimeInterval lastSentTime = [LPRequestStorage sharedStorage].lastSentTime;
        if (!lastSentTime || currentTime - lastSentTime > LP_REQUEST_PRODUCTION_DELAY) {
            [self sendIfConnected];
        }
    }
    LP_END_TRY
}

- (void)sendIfConnected
{
    LP_TRY
    [self sendIfConnectedSync:NO];
    LP_END_TRY
}

- (void)sendIfConnectedSync:(BOOL)sync
{
    if ([[Leanplum_Reachability reachabilityForInternetConnection] isReachable]) {
        if (sync) {
            [self sendNowSync];
        } else {
            [self sendNow];
        }
    } else {
        [self sendEventually];
        if (_error) {
            _error([NSError errorWithDomain:@"Leanplum" code:1
                                   userInfo:@{NSLocalizedDescriptionKey: @"Device is offline"}]);
        }
    }
}

- (void)attachApiKeys:(NSMutableDictionary *)dict
{
    dict[LP_PARAM_APP_ID] = appId;
    dict[LP_PARAM_CLIENT_KEY] = accessKey;
}

- (void)sendNow:(BOOL)async
{
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

    NSArray *requestsToSend = [[LPRequestStorage sharedStorage] popAllRequests];
    
    if (requestsToSend.count == 0) {
        return;
    }

    NSString *requestData = [LeanplumRequest jsonEncodeUnsentRequests:requestsToSend];

    LPConstantsState *constants = [LPConstantsState sharedState];
    NSMutableDictionary *multiRequestArgs = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                             requestData, LP_PARAM_DATA,
                                             constants.sdkVersion, LP_PARAM_SDK_VERSION,
                                             constants.client, LP_PARAM_CLIENT,
                                             LP_METHOD_MULTI, LP_PARAM_ACTION,
                                             [NSString stringWithFormat:@"%f", [[NSDate date] timeIntervalSince1970]], LP_PARAM_TIME, nil];
    [self attachApiKeys:multiRequestArgs];
    int timeout = async ? constants.networkTimeoutSeconds : constants.syncNetworkTimeoutSeconds;
    id<LPNetworkOperationProtocol> op = [engine operationWithPath:constants.apiServlet
                                                         params:multiRequestArgs
                                                     httpMethod:_httpMethod
                                                            ssl:constants.apiSSL
                                                 timeoutSeconds:timeout];
    __block BOOL finished = NO;

    // Schedule timeout.
    [LPTimerBlocks scheduledTimerWithTimeInterval:timeout block:^() {
        if (finished) {
            return;
        }
        finished = YES;
        LP_TRY
        NSLog(@"Leanplum: Request %@ timed out", _apiMethod);
        [op cancel];
        [LeanplumRequest pushUnsentRequests:requestsToSend];
        if (_error != nil) {
            _error([NSError errorWithDomain:@"Leanplum" code:1
                                   userInfo:@{NSLocalizedDescriptionKey: @"Request timed out"}]);
        }
        LP_END_TRY
    } repeats:NO];

    [op addCompletionHandler:^(id<LPNetworkOperationProtocol> operation, id json) {
        if (finished) {
            return;
        }
        finished = YES;
        LP_TRY

        // Handle errors that don't return an HTTP error code.
        NSUInteger numResponses = [LPResponse numResponsesInDictionary:json];
        for (NSUInteger i = 0; i < numResponses; i++) {
            NSDictionary *response = [LPResponse getResponseAt:i fromDictionary:json];
            if (![LPResponse isResponseSuccess:response]) {
                NSString *errorMessage = [LPResponse getResponseError:response];
                if (!errorMessage) {
                    errorMessage = @"API error";
                } else {
                    errorMessage = [NSString stringWithFormat:@"API error: %@", errorMessage];
                }
                NSLog(@"Leanplum: %@", errorMessage);
                if (i == numResponses - 1) {
                    if (_error != nil) {
                        _error([NSError errorWithDomain:@"Leanplum" code:2
                                               userInfo:@{NSLocalizedDescriptionKey: errorMessage}]);
                    }
                    return;
                }
            }
        }
        LP_END_TRY
        if (_response != nil) {
            _response(operation, json);
        }
    } errorHandler:^(id<LPNetworkOperationProtocol> completedOperation, NSError *err) {
        if (finished) {
            return;
        }
        finished = YES;
        LP_TRY
        if (completedOperation.HTTPStatusCode == 408
            || completedOperation.HTTPStatusCode == 502
            || completedOperation.HTTPStatusCode == 503
            || completedOperation.HTTPStatusCode == 504
            || err.code == kCFURLErrorCannotConnectToHost
            || err.code == kCFURLErrorDNSLookupFailed
            || err.code == kCFURLErrorNotConnectedToInternet
            || err.code == kCFURLErrorTimedOut) {
            NSLog(@"Leanplum: %@", err);
            [LeanplumRequest pushUnsentRequests:requestsToSend];
        } else {
            id errorResponse = completedOperation.responseJSON;
            NSString *errorMessage = [LPResponse getResponseError:[LPResponse getLastResponse:errorResponse]];
            if (errorMessage && [errorMessage hasPrefix:@"App not found"]) {
                errorMessage = @"No app matching the provided app ID was found.";
                constants.isInPermanentFailureState = YES;
            } else if (errorMessage && [errorMessage hasPrefix:@"Invalid access key"]) {
                errorMessage = @"The access key you provided is not valid for this app.";
                constants.isInPermanentFailureState = YES;
            } else if (errorMessage && [errorMessage hasPrefix:@"Development mode requested but not permitted"]) {
                errorMessage = @"A call to [Leanplum setAppIdForDevelopmentMode] with your production key was made, which is not permitted.";
                constants.isInPermanentFailureState = YES;
            }
            if (errorMessage) {
                NSLog(@"Leanplum: %@", errorMessage);
            } else {
                NSLog(@"Leanplum: %@", err);
            }
        }
        if (_error != nil) {
            _error(err);
        }
        LP_END_TRY
    }];

    if (async) {
        [engine enqueueOperation: op];
    } else {
        // Execute synchronously. Don't block for more than 'timeout' seconds.
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [engine runSynchronously:op];
        });
        NSTimeInterval startTime = [[NSDate date] timeIntervalSince1970];
        while (!finished && [[NSDate date] timeIntervalSince1970] - startTime < timeout) {
            [NSThread sleepForTimeInterval:0.1];
        }
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
        NSMutableDictionary *args = [self createArgsDictionary];
        [[LPRequestStorage sharedStorage] pushRequest:args];
    }
}

+ (NSString *)jsonEncodeUnsentRequests:(NSArray *)requestData
{
    return [LPJSON stringFromJSON:@{LP_PARAM_DATA:requestData}];
}

+ (void)pushUnsentRequests:(NSArray *)requestData
{
    for (NSMutableDictionary *args in requestData) {
        NSNumber *retryCount = args[@"retryCount"];
        if (!retryCount) {
            retryCount = @1;
        } else {
            retryCount = @([retryCount integerValue] + 1);
        }
        args[@"retryCount"] = retryCount;
        [[LPRequestStorage sharedStorage] pushRequest:args];
    }
    [LeanplumRequest saveRequests];
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
        [LeanplumRequest printUploadProgress];
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
         [LeanplumRequest printUploadProgress];
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
         [LeanplumRequest printUploadProgress];
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

+ (void)saveRequests
{
    LP_TRY
    [[LPRequestStorage sharedStorage] performSelectorInBackground:@selector(saveRequests) withObject:nil];
    LP_END_TRY
}

@end

@implementation LPResponse

+ (NSUInteger)numResponsesInDictionary:(NSDictionary *)dictionary
{
    return [dictionary[@"response"] count];
}

+ (NSDictionary *)getResponseAt:(NSUInteger)index fromDictionary:(NSDictionary *)dictionary
{
    return [dictionary[@"response"] objectAtIndex:index];
}

+ (NSDictionary *)getLastResponse:(NSDictionary *)dictionary
{
    return [LPResponse getResponseAt:[LPResponse numResponsesInDictionary:dictionary] - 1
                      fromDictionary:dictionary];
}

+ (BOOL)isResponseSuccess:(NSDictionary *)dictionary
{
    return [dictionary[@"success"] boolValue];
}

+ (NSString *)getResponseError:(NSDictionary *)dictionary
{
    return dictionary[@"error"][@"message"];
}

@end
