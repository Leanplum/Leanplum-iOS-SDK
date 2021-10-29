//
//  LPNotificationsManager.m
//  Leanplum-iOS-SDK
//
//  Created by Dejan Krstevski on 15.05.20.
//  Copyright © 2020 Leanplum. All rights reserved.
//

#import "LPNotificationsManager.h"
#import "LPNotificationsConstants.h"
#import "LPPushNotificationsManager.h"

@implementation LPNotificationsManager

+ (LPNotificationsManager *)shared
{
    static LPNotificationsManager *_sharedManager = nil;
    static dispatch_once_t notificationsHelperToken;
    dispatch_once(&notificationsHelperToken, ^{
        _sharedManager = [[self alloc] init];
    });
    return _sharedManager;
}

- (NSString *)hexadecimalStringFromData:(NSData *)data
{
    NSUInteger dataLength = data.length;
    if (dataLength == 0) {
        return nil;
    }

    const unsigned char *dataBuffer = data.bytes;
    NSMutableString *hexString  = [NSMutableString stringWithCapacity:(dataLength * 2)];
    for (int i = 0; i < dataLength; ++i) {
        [hexString appendFormat:@"%02x", dataBuffer[i]];
    }
    return [hexString copy];
}

@end
