//
//  CleverTapInstanceCallback.m
//  LeanplumSDK
//
//  Created by Nikola Zagorchev on 21.11.22.
//  Copyright © 2022 Leanplum. All rights reserved.

#import "CleverTapInstanceCallback.h"

@interface CleverTapInstanceCallback()
@property (atomic, nonnull) LeanplumCleverTapInstanceBlock block;
@end

@implementation CleverTapInstanceCallback

- (instancetype)initWithCallback:(LeanplumCleverTapInstanceBlock)block
{
    self = [super init];
    if (self) {
        self.block = block;
    }
    return self;
}

- (void)onInstance:(CleverTap *)instance
{
    self.block(instance);
}

@end
