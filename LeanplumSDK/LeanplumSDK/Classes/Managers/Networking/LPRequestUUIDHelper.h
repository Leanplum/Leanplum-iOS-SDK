//
//  LPRequestUUIDHelper.h
//  Leanplum-iOS-SDK
//
//  Copyright © 2020 Leanplum. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LPRequestUUIDHelper : NSObject
+ (NSString *)generateUUID;
+ (NSString *)loadUUID;
@end

NS_ASSUME_NONNULL_END
