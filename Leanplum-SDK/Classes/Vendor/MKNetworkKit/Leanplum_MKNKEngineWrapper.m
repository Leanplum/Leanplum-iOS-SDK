//
//  Leanplum_MKNKEngineWrapper.m
//  Leanplum
//
//  Created by Alexis Oyama on 11/14/16.
//  Copyright (c) 2016 Leanplum, Inc. All rights reserved.
//
#import <Foundation/Foundation.h>

#if __IPHONE_OS_VERSION_MIN_REQUIRED < 70000

#import "Leanplum_MKNKEngineWrapper.h"
#import "Leanplum_MKNKOperationWrapper.h"

@implementation Leanplum_MKNKEngineWrapper

- (id)initWithHostName:(NSString*)hostName customHeaderFields:(NSDictionary*)headers
{
    self = [self init];
    self.engine = [[Leanplum_MKNetworkEngine alloc] initWithHostName:hostName
                                             customHeaderFields:headers];
    return self;
}

- (id)initWithHostName:(NSString *)hostName
{
    self = [self init];
    self.engine = [[Leanplum_MKNetworkEngine alloc] initWithHostName:hostName];
    return self;
}

- (id<LPNetworkOperationProtocol>)operationWithPath:(NSString*) path
                                             params:(NSMutableDictionary*) body
                                         httpMethod:(NSString*)method
                                                ssl:(BOOL) useSSL
                                     timeoutSeconds:(int)timeout
{
    Leanplum_MKNKOperationWrapper *op = [Leanplum_MKNKOperationWrapper new];
    op.operation = [self.engine operationWithPath:path params:body
                                       httpMethod:method ssl:useSSL
                                   timeoutSeconds:timeout];
    return op;
}

- (id<LPNetworkOperationProtocol>)operationWithURLString:(NSString *)urlString
                                                  params:(NSMutableDictionary *)body
                                              httpMethod:(NSString *)method
                                          timeoutSeconds:(int)timeout
{
    Leanplum_MKNKOperationWrapper *op = [Leanplum_MKNKOperationWrapper new];
    op.operation = [self.engine operationWithURLString:urlString params:body
                                            httpMethod:method timeoutSeconds:timeout];
    return op;
}

- (id<LPNetworkOperationProtocol>)operationWithURLString:(NSString *)urlString
{
    Leanplum_MKNKOperationWrapper *op = [Leanplum_MKNKOperationWrapper new];
    op.operation = [self.engine operationWithURLString:urlString];
    return op;
}

- (void)enqueueOperation:(id<LPNetworkOperationProtocol>)operation
{
    if ([operation isKindOfClass:[Leanplum_MKNKOperationWrapper class]]) {
        Leanplum_MKNKOperationWrapper *wrapper = operation;
        [self.engine enqueueOperation:wrapper.operation];
    }
}

- (void)runSynchronously:(id<LPNetworkOperationProtocol>)operation
{
    if ([operation isKindOfClass:[Leanplum_MKNKOperationWrapper class]]) {
        Leanplum_MKNKOperationWrapper *wrapper = operation;
        [self.engine runSynchronously:wrapper.operation];
    }
}

@end

#endif
