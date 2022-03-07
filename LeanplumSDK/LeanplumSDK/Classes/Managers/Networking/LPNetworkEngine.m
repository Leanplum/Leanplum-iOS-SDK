//
//  LPNetworkEngine.m
//  Leanplum
//
//  Created by Alexis Oyama on 11/14/16.
//  Copyright (c) 2016 Leanplum, Inc. All rights reserved.
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

#import "LPNetworkEngine.h"
#import "LPNetworkOperation.h"
#import "LeanplumInternal.h"
#import "LPCountAggregator.h"
#import <Leanplum/Leanplum-Swift.h>

@interface LPNetworkEngine()

@property (nonatomic, strong)NSURLRequest *request;
@property (nonatomic, strong) LPCountAggregator *countAggregator;

@end

@implementation LPNetworkEngine

/**
 * Initialize default NSURLSession. Should not be used in public.
 */
- (id)init
{
    if (self = [super init]) {
        self.sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
        self.sessionConfiguration.URLCache = nil;
        self.sessionConfiguration.URLCredentialStorage = nil;
        self.sessionConfiguration.requestCachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
        self.countAggregator = [LPCountAggregator sharedAggregator];
    }
    return self;
}

- (id)initWithCustomHeaderFields:(NSDictionary *)headers
{
    self = [self init];
    self.sessionConfiguration.HTTPAdditionalHeaders = headers;

    return self;
}

- (void)dealloc
{
    self.sessionConfiguration = nil;
}

- (id<LPNetworkOperationProtocol>)operationWithHost:(NSString *)host
                                               path:(NSString *)path
                                             params:(NSMutableDictionary *)body
                                         httpMethod:(NSString *)method
                                                ssl:(BOOL)useSSL
                                     timeoutSeconds:(int)timeout
{
    NSMutableString *urlString = [NSMutableString stringWithFormat:@"%@://%@",
                                  useSSL ? @"https" : @"http", host];
    [urlString appendFormat:@"/%@", path];
    
    [self.countAggregator incrementCount:@"operation_with_path"];
    
    return [self operationWithURLString:urlString params:body httpMethod:method
                         timeoutSeconds:timeout];
}

- (id<LPNetworkOperationProtocol>)operationWithURLString:(NSString *)urlString
                                                  params:(NSMutableDictionary *)body
                                              httpMethod:(NSString *)method
                                          timeoutSeconds:(int)timeout
{
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url
                                    cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                    timeoutInterval:timeout];
    request.HTTPMethod = method;
    return [[LPNetworkOperation alloc] initWithSessionConfiguration:self.sessionConfiguration
                                                            request:request param:body];
}

- (id<LPNetworkOperationProtocol>)operationWithURLString:(NSString *)urlString
{
    [self.countAggregator incrementCount:@"operation_with_url_string"];
    return [self operationWithURLString:urlString params:nil httpMethod:@"GET"
                         timeoutSeconds:[LPConstantsState sharedState].networkTimeoutSeconds];
}

- (void)enqueueOperation:(id<LPNetworkOperationProtocol>)operation
{
    if ([operation isKindOfClass:[LPNetworkOperation class]]) {
        [(LPNetworkOperation *)operation run];
    } else {
        LPLog(LPError, @"LPNetworkOperation is not used with LPNetworkEngine");
    }
    [self.countAggregator incrementCount:@"enqueue_operation"];
}

- (void)runSynchronously:(id<LPNetworkOperationProtocol>)operation
{
    if ([operation isKindOfClass:[LPNetworkOperation class]]) {
        [(LPNetworkOperation *)operation runSynchronously:YES];
    } else {
        LPLog(LPError, @"LPNetworkOperation is not used with LPNetworkEngine");
    }
}

/*
 Must include `Accept-Encoding: gzip` in the header
 Must include the phrase `gzip` in the `User-Agent` header
 https://cloud.google.com/appengine/kb/
 */
+ (NSDictionary *)createHeaders {
    NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
    NSString *userAgentString = [NSString stringWithFormat:@"%@/%@/%@/%@/%@/%@/%@/%@/%@",
                                 infoDict[(NSString *)kCFBundleNameKey],
                                 infoDict[(NSString *)kCFBundleVersionKey],
                                 [[ApiConfig shared] appId],
                                 LEANPLUM_CLIENT,
                                 LEANPLUM_SDK_VERSION,
                                 [[UIDevice currentDevice] systemName],
                                 [[UIDevice currentDevice] systemVersion],
                                 LEANPLUM_SUPPORTED_ENCODING,
                                 LEANPLUM_PACKAGE_IDENTIFIER];
    
    NSString *languageHeader = [NSString stringWithFormat:@"%@, en-us",
                                [[NSLocale preferredLanguages] componentsJoinedByString:@", "]];
    
    return @{@"User-Agent": userAgentString, @"Accept-Language" : languageHeader, @"Accept-Encoding" : LEANPLUM_SUPPORTED_ENCODING};
}

@end
