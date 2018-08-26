//
//  LPFeatureFlagManager.h
//  Leanplum-iOS-SDK-source
//
//  Created by Mayank Sanganeria on 7/25/18.
//

#import <Foundation/Foundation.h>
#import "LPFeatureFlags.h"

@interface LPFeatureFlagManager : NSObject

+ (instancetype)sharedManager;
-(BOOL)isFeatureFlagEnabled:(NSString *)featureFlagName;

@end
