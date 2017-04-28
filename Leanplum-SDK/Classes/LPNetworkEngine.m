//
//  LPNetworkEngine.m
//  Leanplum
//
//  Created by Alexis Oyama on 11/14/16.
//  Copyright (c) 2016 Leanplum. All rights reserved.
//

#import "LPNetworkEngine.h"
#import "LPNetworkOperation.h"
#import "LeanplumInternal.h"

@interface LPNetworkEngine()

@property (nonatomic, copy) NSString *hostName;
@property (nonatomic, strong)NSURLRequest *request;

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
        _hostName = @"";
    }
    return self;
}

- (id)initWithHostName:(NSString *)hostName customHeaderFields:(NSDictionary *)headers
{
    self = [self init];
    self.sessionConfiguration.HTTPAdditionalHeaders = headers;
    self.hostName = hostName;

    return self;
}

- (id)initWithHostName:(NSString *)hostName
{
    self = [self init];
    self.hostName = hostName;

    return self;
}

- (void)dealloc
{
    self.sessionConfiguration = nil;
}

- (void)setHostName:(NSString *)hostName
{
    _hostName = hostName;

    self.reachability = [Leanplum_Reachability reachabilityWithHostname:_hostName];
    [self.reachability startNotifier];
}

- (id<LPNetworkOperationProtocol>)operationWithPath:(NSString *)path
                                             params:(NSMutableDictionary *)body
                                         httpMethod:(NSString *)method
                                                ssl:(BOOL)useSSL
                                     timeoutSeconds:(int)timeout
{
    NSMutableString *urlString = [NSMutableString stringWithFormat:@"%@://%@",
                                  useSSL ? @"https" : @"http", self.hostName];
    [urlString appendFormat:@"/%@", path];
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
    [request setValue:[NSString stringWithFormat:@"%@, en-us",
                       [[NSLocale preferredLanguages] componentsJoinedByString:@", "]]
                        forHTTPHeaderField:@"Accept-Language"];
    return [[LPNetworkOperation alloc] initWithSessionConfiguration:self.sessionConfiguration
                                                            request:request param:body];
}

- (id<LPNetworkOperationProtocol>)operationWithURLString:(NSString *)urlString
{
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
}

- (void)runSynchronously:(id<LPNetworkOperationProtocol>)operation
{
    if ([operation isKindOfClass:[LPNetworkOperation class]]) {
        [(LPNetworkOperation *)operation runSynchronously:YES];
    } else {
        LPLog(LPError, @"LPNetworkOperation is not used with LPNetworkEngine");
    }
}

@end
