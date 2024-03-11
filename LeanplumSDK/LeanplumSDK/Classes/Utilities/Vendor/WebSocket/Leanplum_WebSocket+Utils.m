//
//  Leanplum_WebSocket+Utils.m
//  LeanplumSDK
//
//  Created by Nikola Zagorchev on 31.01.24.
//  Copyright © 2024 Leanplum. All rights reserved.

#import "Leanplum_WebSocket+Utils.h"
#import "LPLogManager.h"

NSString* const kUpgradeHeader = @"upgrade:";
NSString* const kConnectionHeader = @"connection:";
NSString* const kStatusCodeString = @"101";

NSString* const kUpgradeHeaderExpected = @"websocket";
NSString* const kConnectionHeaderExpected = @"upgrade";

@implementation Leanplum_WebSocket (Utils)

+ (BOOL)isHandshakeSuccessful:(NSString *)response {
    /* 
     Check the status code and headers.
     Status code is the second value, after the protocol.
     Headers are case insensitive.
     Example reponse string (new lines can be \r\n or \n):
    @"HTTP/1.1 101 Switching Protocols\r\n\
    WebSocket-Origin: http://dev.leanplum.com\r\n\
    WebSocket-Location: ws://dev.leanplum.com/socket.io/1/websocket/y12oUiE3teSTh4S5TeSt\r\n\
    Date: Wed, 31 Jan 2024 15:27:15 GMT\r\n\
    Via: 1.1 google\r\n\
    Upgrade: websocket\r\n\
    Connection: Upgrade";
     */
    
    NSArray *lines = [response componentsSeparatedByString:@"\n"];
    NSString *firstLine = [lines firstObject];
    NSArray *firstLineComponents = [firstLine componentsSeparatedByString:@" "];
    if ([firstLineComponents count] > 2) {
        NSString *statusCode = firstLineComponents[1];
        if ([statusCode isEqualToString:kStatusCodeString]) {
            // Iterate through the lines to find Upgrade and Connection values
            NSString *upgradeValue;
            NSString *connectionValue;
            for (NSString *line in lines) {
                NSString *lineLowercase = [line lowercaseString];
                if ([lineLowercase hasPrefix:kUpgradeHeader]) {
                    upgradeValue = [line substringFromIndex:[kUpgradeHeader length]];
                } else if ([lineLowercase hasPrefix:kConnectionHeader]) {
                    connectionValue = [line substringFromIndex:[kConnectionHeader length]];
                }
            }
            if ([[upgradeValue lowercaseString] containsString:kUpgradeHeaderExpected] &&
                [[connectionValue lowercaseString] containsString:kConnectionHeaderExpected]) {
                return YES;
            }
            LPLog(LPDebug, @"Invalid Upgrade and/or Connection headers. Upgrade: %@, Connection: %@.", upgradeValue, connectionValue);
        } else {
            LPLog(LPDebug, @"Invalid Status Code: %@, line: %@.", statusCode, [lines firstObject]);
        }
    }

    return NO;
}

@end
