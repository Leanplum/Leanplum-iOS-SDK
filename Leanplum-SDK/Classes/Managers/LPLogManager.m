//
//  LPLogManager.m
//  Leanplum-iOS-SDK
//
//  Created by Dejan Krstevski on 31.07.20.
//  Copyright (c) 2020 Leanplum, Inc. All rights reserved.
//

#import "LPLogManager.h"
#import "LPUtils.h"
#import "LPConstants.h"
#import "LPRequestFactory.h"
#import "LPRequestSender.h"


@interface LPLogManager()
@property (nonatomic, retain) NSDateFormatter *dateFormatter;
+ (void)maybeSendLog:(NSString *)message;
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

+ (void)maybeSendLog:(NSString *)message {
    if (![LPConstantsState sharedState].loggingEnabled) {
        return;
    }

    NSMutableDictionary *threadDict = [[NSThread currentThread] threadDictionary];
    BOOL isLogging = [[[[NSThread currentThread] threadDictionary]
                       objectForKey:LP_IS_LOGGING] boolValue];

    if (isLogging) {
        return;
    }

    threadDict[LP_IS_LOGGING] = @YES;

    @try {
        LPRequestFactory *reqFactory = [[LPRequestFactory alloc]
                                        initWithFeatureFlagManager:[LPFeatureFlagManager sharedManager]];
        id<LPRequesting> request = [reqFactory logWithParams:@{
                                                      LP_PARAM_TYPE: LP_VALUE_SDK_LOG,
                                                      LP_PARAM_MESSAGE: message
                                                      }];
                [[LPRequestSender sharedInstance] sendEventually:request sync:NO];
    } @catch (NSException *exception) {
        NSLog(@"Leanplum: Unable to send log: %@", exception);
    } @finally {
        [threadDict removeObjectForKey:LP_IS_LOGGING];
    }
}

+ (void)logInternalError:(NSException *)e
{
    [LPUtils handleException:e];
    if ([e.name isEqualToString:@"Leanplum Error"]) {
        @throw e;
    }
    
    for (id symbol in [e callStackSymbols]) {
        NSString *description = [symbol description];
        if ([description rangeOfString:@"+[Leanplum trigger"].location != NSNotFound
            || [description rangeOfString:@"+[Leanplum throw"].location != NSNotFound
            || [description rangeOfString:@"-[LPVar trigger"].location != NSNotFound
            || [description rangeOfString:@"+[Leanplum setApiHostName"].location != NSNotFound) {
            @throw e;
        }
    }
    NSString *versionName = [[[NSBundle mainBundle] infoDictionary]
                             objectForKey:@"CFBundleVersion"];
    if (!versionName) {
        versionName = @"";
    }
    int userCodeBlocks = [[[[NSThread currentThread] threadDictionary]
                           objectForKey:LP_USER_CODE_BLOCKS] intValue];
    if (userCodeBlocks <= 0) {
        @try {
            LPRequestFactory *reqFactory = [[LPRequestFactory alloc]
                                            initWithFeatureFlagManager:[LPFeatureFlagManager sharedManager]];
            id<LPRequesting> request = [reqFactory logWithParams:@{
                                     LP_PARAM_TYPE: LP_VALUE_SDK_ERROR,
                                     LP_PARAM_MESSAGE: [e description],
                                     @"stackTrace": [[e callStackSymbols] description] ?: @"",
                                     LP_PARAM_VERSION_NAME: versionName
                                     }];
            [[LPRequestSender sharedInstance] send:request];
        } @catch (NSException *e) {
            // This empty try/catch is needed to prevent crash <-> loop.
        }
        NSLog(@"Leanplum: INTERNAL ERROR: %@\n%@", e, [e callStackSymbols]);
    } else {
        NSLog(@"Leanplum: Caught exception in callback code: %@\n%@", e, [e callStackSymbols]);
        LP_END_USER_CODE
        @throw e;
    }
}

@end

void LPLogNew(LPLogTypeNew type , NSString *format, ...) {
    LPLogLevel level = [[LPLogManager sharedManager] logLevel];
    NSString *message = nil;
    NSString *leanplumString = @"LEANPLUM";
    NSString *dateString = [[LPLogManager sharedManager].dateFormatter stringFromDate:[NSDate date]];
    NSString *logType = nil;
    
    switch (type) {
        case LPDebugNew:
            logType = @"DEBUG";
            message = [NSString stringWithFormat:@"[%@] [%@] [%@]: %@", dateString, leanplumString, logType, format];
            [LPLogManager maybeSendLog:message];
            if (level < Debug) {
                return;
            }
            break;
        case LPInfoNew:
            logType = @"INFO";
            message = [NSString stringWithFormat:@"[%@] [%@] [%@]: %@", dateString, leanplumString, logType, format];
            [LPLogManager maybeSendLog:message];
            if (level < Info) {
                return;
            }
            break;
        case LPErrorNew:
            logType = @"ERROR";
            message = [NSString stringWithFormat:@"[%@] [%@] [%@]: %@", dateString, leanplumString, logType, format];
            [LPLogManager maybeSendLog:message];
            if (level < Error) {
                return;
            }
            break;
    }
    
    printf("%s\n", [message UTF8String]);
}
