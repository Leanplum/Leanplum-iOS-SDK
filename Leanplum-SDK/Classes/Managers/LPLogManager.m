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
+ (void)maybeSendLog:(NSString *)message;
@end
@implementation LPLogManager
static LPLogLevel logLevel = Info;

+(void)setLogLevel:(LPLogLevel)level
{
    @synchronized (self) {
        logLevel = level;
    }
}

+(LPLogLevel)logLevel
{
    @synchronized (self) {
        return logLevel;
    }
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
        LPRequest *request = [LPRequestFactory logWithParams:@{
                                                      LP_PARAM_TYPE: LP_VALUE_SDK_LOG,
                                                      LP_PARAM_MESSAGE: message
                                                      }];
                [[LPRequestSender sharedInstance] send:request];
    } @catch (NSException *exception) {
        LPLog(LPError, @"Unable to send log: %@", exception);
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
    NSString *versionName = [Leanplum appVersion];
    if (!versionName) {
        versionName = @"";
    }
    int userCodeBlocks = [[[[NSThread currentThread] threadDictionary]
                           objectForKey:LP_USER_CODE_BLOCKS] intValue];
    if (userCodeBlocks <= 0) {
        @try {
            NSString *description = [e description];
            NSString *stackTrace = [[e callStackSymbols] description] ?: @"";
            NSString *message = [NSString stringWithFormat:@"%@\n%@", description, stackTrace];
            LPRequest *request = [LPRequestFactory logWithParams:@{
                                     LP_PARAM_TYPE: LP_VALUE_SDK_LOG,
                                     LP_PARAM_MESSAGE: message,
                                     LP_PARAM_VERSION_NAME: versionName
                                     }];
            [[LPRequestSender sharedInstance] send:request];
        } @catch (NSException *e) {
            // This empty try/catch is needed to prevent crash <-> loop.
        }
        LPLog(LPError, @"%@\n%@", e, [e callStackSymbols]);
    } else {
        LPLog(LPError, @"Caught exception in callback code: %@\n%@", e, [e callStackSymbols]);
        LP_END_USER_CODE
        @throw e;
    }
}

@end

void LPLog(LPLogType type, NSString *format, ...) {
    va_list vargs;
    va_start(vargs, format);
    NSString *formattedMessage = [[NSString alloc] initWithFormat:format arguments:vargs];
    va_end(vargs);
    
    LPLogLevel level = [LPLogManager logLevel];
    NSString *message = nil;
    NSString *leanplumString = @"LEANPLUM";
    NSString *logType = nil;
    
    switch (type) {
        case LPDebug:
            logType = @"DEBUG";
            message = [NSString stringWithFormat:@"[%@] [%@]: %@", leanplumString, logType, formattedMessage];
            [LPLogManager maybeSendLog:message];
            if (level < Debug) {
                return;
            }
            break;
        case LPInfo:
            logType = @"INFO";
            message = [NSString stringWithFormat:@"[%@] [%@]: %@", leanplumString, logType, formattedMessage];
            [LPLogManager maybeSendLog:message];
            if (level < Info) {
                return;
            }
            break;
        case LPError:
            logType = @"ERROR";
            message = [NSString stringWithFormat:@"[%@] [%@]: %@", leanplumString, logType, formattedMessage];
            [LPLogManager maybeSendLog:message];
            if (level < Error) {
                return;
            }
            break;
    }
    
    NSLog(@"%@", message);
}
