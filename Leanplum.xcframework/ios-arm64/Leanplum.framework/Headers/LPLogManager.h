//
//  LPLogManager.h
//  Leanplum-iOS-SDK
//
//  Created by Dejan Krstevski on 31.07.20.
//  Copyright (c) 2020 Leanplum, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, LPLogLevel) {
    LPLogLevelOff = 0,
    LPLogLevelError,
    LPLogLevelInfo,
    LPLogLevelDebug
} NS_SWIFT_NAME(LeanplumLogLevel);

typedef NS_ENUM(NSUInteger, LPLogType) {
    LPError,
    LPInfo,
    LPDebug
} NS_SWIFT_NAME(LeanplumLogType);

@interface LPLogManager : NSObject
@property (nonatomic, assign) LPLogLevel logLevel;
+ (void)setLogLevel:(LPLogLevel)level;
+ (LPLogLevel)logLevel;
+ (void)logInternalError:(NSException *)e;
@end

NS_ASSUME_NONNULL_END
void LPLog(LPLogType type, NSString * _Nullable format, ...);
void LPLogv(LPLogType type, NSString * _Nullable format, va_list args);
