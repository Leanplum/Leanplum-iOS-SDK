//
//  LPNetworkFactory.h
//  Leanplum
//
//  Copyright (c) 2018 Leanplum, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LPNetworkProtocol.h"

/**
 * Network Factory that creates an engine depending if
 * device has NSURLSession (iOS > 7).
 */
@interface LPNetworkFactory : NSObject

+ (id<LPNetworkEngineProtocol>)engineWithHostName:(NSString*)hostName
                               customHeaderFields:(NSDictionary*)headers;
+ (id<LPNetworkEngineProtocol>)engineWithHostName:(NSString*)hostName;

/**
 * Workaround to use POST on new and GET on old networking library.
 */
+ (NSString *)fileRequestMethod;

@end
