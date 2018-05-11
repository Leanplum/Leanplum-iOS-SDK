//
//  LPNetworkFactory.m
//  Leanplum
//
//  Copyright (c) 2018 Leanplum, Inc. All rights reserved.
//

#import "LPNetworkFactory.h"
#import "LPNetworkEngine.h"
#import "LPNetworkOperation.h"
#import "Leanplum_MKNKOperationWrapper.h"
#import "Leanplum_MKNKEngineWrapper.h"

@implementation LPNetworkFactory

+ (id<LPNetworkEngineProtocol>)engineWithHostName:(NSString*)hostName
                               customHeaderFields:(NSDictionary*)headers
{
#if __IPHONE_OS_VERSION_MIN_REQUIRED < 70000
    if (!NSClassFromString(@"NSURLSession")) {
        return [[Leanplum_MKNKEngineWrapper alloc] initWithHostName:hostName
                                                 customHeaderFields:headers];
    }
#endif
    return [[LPNetworkEngine alloc] initWithHostName:hostName
                                  customHeaderFields:headers];
}

+ (id<LPNetworkEngineProtocol>)engineWithHostName:(NSString*)hostName
{
#if __IPHONE_OS_VERSION_MIN_REQUIRED < 70000
    if (!NSClassFromString(@"NSURLSession")) {
        return [[Leanplum_MKNKEngineWrapper alloc] initWithHostName:hostName];
    }
#endif
    return [[LPNetworkEngine alloc] initWithHostName:hostName];
}

+ (NSString *)fileRequestMethod
{
#if __IPHONE_OS_VERSION_MIN_REQUIRED < 70000
    if (!NSClassFromString(@"NSURLSession")) {
        return [Leanplum_MKNKOperationWrapper fileRequestMethod];
    }
#endif
    return [LPNetworkOperation fileRequestMethod];
}

@end
