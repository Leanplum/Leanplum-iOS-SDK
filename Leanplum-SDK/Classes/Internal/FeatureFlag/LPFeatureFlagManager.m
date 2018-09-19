//
//  LPFeatureFlagManager.m
//  Leanplum-iOS-SDK-source
//
//  Created by Mayank Sanganeria on 7/25/18.
//

#import "LPFeatureFlagManager.h"

@implementation LPFeatureFlagManager

static LPFeatureFlagManager *sharedFeatureFlagManager = nil;
static dispatch_once_t leanplum_onceToken;

+ (instancetype)sharedManager {
    dispatch_once(&leanplum_onceToken, ^{
        sharedFeatureFlagManager = [[self alloc] init];
    });
    return sharedFeatureFlagManager;
}

- (BOOL)isFeatureFlagEnabled:(nonnull NSString *)featureFlagName {
    return [self.enabledFeatureFlags containsObject:featureFlagName];
}

@end
