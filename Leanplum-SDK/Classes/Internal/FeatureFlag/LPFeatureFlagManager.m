//
//  LPFeatureFlagManager.m
//  Leanplum-iOS-SDK-source
//
//  Created by Mayank Sanganeria on 7/25/18.
//

#import "LPFeatureFlagManager.h"

@interface LPFeatureFlagManager()

@property (strong, nonatomic) NSSet *enabledFeatureFlags;

@end

@implementation LPFeatureFlagManager

static LPFeatureFlagManager *sharedFeatureFlagManager = nil;
static dispatch_once_t leanplum_onceToken;

+ (instancetype)sharedManager {
    dispatch_once(&leanplum_onceToken, ^{
        sharedFeatureFlagManager = [[self alloc] init];
    });
    return sharedFeatureFlagManager;
}

-(void)refreshEnabledFeatureFlags:(nullable NSArray<NSString *> *)featureFlags {
    if (featureFlags != nil) {
        self.enabledFeatureFlags = [NSSet setWithArray:featureFlags];
    }
}

-(BOOL)isFeatureFlagEnabled:(nonnull NSString *)featureFlagName {
    return [self.enabledFeatureFlags containsObject:featureFlagName];
}

@end
