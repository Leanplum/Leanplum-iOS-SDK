//
//  LPPushAsktoAskMessageTemplate.h
//  LeanplumSDK-iOS
//
//  Created by Mayank Sanganeria on 2/6/20.
//  Copyright © 2020 Leanplum. All rights reserved.
//

#import "LPMessageTemplateProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface LPPrePushMessageTemplate : NSObject <LPMessageTemplateProtocol>

- (void)enableSystemPush;
- (void)refreshPushPermissions;
- (BOOL)hasDisabledAskToAsk;

@end

NS_ASSUME_NONNULL_END
