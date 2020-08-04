//
//  LPLogManager.m
//  Leanplum-iOS-SDK
//
//  Created by Dejan Krstevski on 31.07.20.
//  Copyright (c) 2020 Leanplum, Inc. All rights reserved.
//

#import "LPLogManager.h"

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
    }
    return self;
}

@end

void LPLogNew(LPLogLevel level , NSString *format, ...) {
    if (level == Debug && [LPLogManager sharedManager].logLevel != Debug) {
        return;
    }
    
    NSString *logType = @"";
    switch (level) {
        case Debug:
            logType = @"DEBUG";
            break;
        case Info:
            logType = @"INFO";
            break;
        case Error:
            logType = @"ERROR";
            break;
        default:
            logType = @"INFO";
            break;
    }
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setTimeStyle:NSDateFormatterLongStyle];
    [formatter setDateStyle:NSDateFormatterLongStyle];
    [formatter setLocale:[NSLocale currentLocale]];
    NSDate *todaysDate = [NSDate date];
    printf("[%s] [LEANPLUM] [%s]: %s\n", [[formatter stringFromDate:todaysDate] UTF8String], [logType UTF8String], [format UTF8String]);
}
