//
//  CleverTapInstanceCallback.h
//  LeanplumSDK
//
//  Created by Nikola Zagorchev on 21.11.22.
//  Copyright © 2022 Leanplum. All rights reserved.

#import <Foundation/Foundation.h>
// Forward declaration for CleverTap instance
@class CleverTap;

NS_ASSUME_NONNULL_BEGIN

typedef void (^LeanplumCleverTapInstanceBlock)(CleverTap* instance);

@interface CleverTapInstanceCallback : NSObject

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithCallback:(LeanplumCleverTapInstanceBlock)block;

- (void)onInstance:(CleverTap *)instance;

@end

NS_ASSUME_NONNULL_END
