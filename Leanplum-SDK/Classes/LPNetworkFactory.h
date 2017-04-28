//
//  LPNetworkFactory.h
//  Leanplum
//
//  Created by Alexis Oyama on 11/14/16.
//  Copyright (c) 2016 Leanplum. All rights reserved.
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
