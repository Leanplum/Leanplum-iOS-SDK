//
//  LPFeatureFlagManager.h
//  Leanplum-iOS-SDK-source
//
//  Created by Mayank Sanganeria on 7/25/18.
//

#import <Foundation/Foundation.h>

#define LP_FEATURE_FLAG_REQUEST_REFACTOR @"LP_FEATURE_FLAG_REQUEST_REFACTOR"

@interface LPFeatureFlagManager : NSObject

+ (instancetype)sharedManager;
-(BOOL)isFeatureFlagEnabled:(NSString *)featureFlagName;

@end
