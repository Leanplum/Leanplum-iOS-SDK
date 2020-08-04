//
//  LPLogManager.m
//  Leanplum-iOS-SDK
//
//  Created by Dejan Krstevski on 31.07.20.
//  Copyright (c) 2020 Leanplum, Inc. All rights reserved.
//

#import "LPLogManager.h"
@interface LPLogManager()
@property (nonatomic, retain) NSDateFormatter *dateFormatter;
@end
@implementation LPLogManager

+ (LPLogManager *)sharedManager
{
    static LPLogManager *_sharedManager = nil;
    static dispatch_once_t logManagerToken;
    dispatch_once(&logManagerToken, ^{
        _sharedManager = [[self alloc] init];
    });
    return _sharedManager;
}

- (instancetype)init
{
    if (self = [super init]) {
        _logLevel = Info;
        _dateFormatter = [[NSDateFormatter alloc] init];
        [_dateFormatter setDateFormat:@"dd.MM.yyyy HH:mm:ss"];
    }
    return self;
}

@end

void LPLogNew(LPLogTypeNew type , NSString *format, ...) {
    LPLogLevel level = [[LPLogManager sharedManager] logLevel];
    NSString *logType = @"";
    switch (type) {
        case LPDebugNew:
            if (level < Debug) {
                return;
            }
            logType = @"DEBUG";
            break;
        case LPInfoNew:
            if (level < Info) {
                return;
            }
            logType = @"INFO";
            break;
        case LPErrorNew:
            if (level < Error) {
                return;
            }
            logType = @"ERROR";
            break;
        default:
            logType = @"INFO";
            break;
    }
    
    printf("[%s] [LEANPLUM] [%s]: %s\n", [[[LPLogManager sharedManager].dateFormatter stringFromDate:[NSDate date]] UTF8String], [logType UTF8String], [format UTF8String]);
}
