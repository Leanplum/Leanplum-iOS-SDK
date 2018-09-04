//
//  LPFeatureFlagManager.h
//  Leanplum-iOS-SDK-source
//
//  Created by Mayank Sanganeria on 7/25/18.
//

#import <Foundation/Foundation.h>
#import "LPFeatureFlags.h"

@interface LPFeatureFlagManager : NSObject

+ (_Nonnull instancetype)sharedManager;

-(void)refreshEnabledFeatureFlags:(nullable NSArray<NSString *> *)featureFlags;
-(BOOL)isFeatureFlagEnabled:(nonnull NSString *)featureFlagName;

@end
