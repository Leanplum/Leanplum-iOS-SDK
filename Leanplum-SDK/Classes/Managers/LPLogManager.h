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
    Debug,
    Info,
    Error
} NS_SWIFT_NAME(Leanplum.LogLevel);

@interface LPLogManager : NSObject
@property (nonatomic, assign) LPLogLevel logLevel;
+ (LPLogManager *)sharedManager;
@end

NS_ASSUME_NONNULL_END
void LPLogNew(LPLogLevel level, NSString * _Nullable format, ...);
