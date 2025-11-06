//
//  Leanplum_WebSocket+Utils.h
//  LeanplumSDK
//
//  Created by Nikola Zagorchev on 31.01.24.
//  Copyright © 2024 Leanplum. All rights reserved.

#import <Foundation/Foundation.h>
#import "Leanplum_WebSocket.h"

NS_ASSUME_NONNULL_BEGIN

@interface Leanplum_WebSocket (Utils)

/**
 * Checks if the socket handshake response is successful.
 * Validates the HTTP status code, Upgrade and Connection headers.
 * @param response The handshake string response.
 */
+ (BOOL)isHandshakeSuccessful:(NSString *)response;

@end

NS_ASSUME_NONNULL_END
