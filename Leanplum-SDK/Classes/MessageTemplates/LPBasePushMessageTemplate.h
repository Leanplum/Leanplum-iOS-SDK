//
//  LPBasePushMessageTemplate.h
//  LeanplumSDK-iOS
//
//  Created by Mayank Sanganeria on 2/7/20.
//  Copyright © 2020 Leanplum. All rights reserved.
//

#import "LPBaseInterstitialMessageTemplate.h"

NS_ASSUME_NONNULL_BEGIN

@interface LPBasePushMessageTemplate : LPBaseInterstitialMessageTemplate

- (void)enablePush;
- (void)deferPush;
- (BOOL)isPushEnabled;
- (void)enableSystemPush;
- (void)refreshPushPermissions;
- (void)accept;
- (BOOL)hasDisabledAskToAsk;

@end

NS_ASSUME_NONNULL_END
