//
//  LPPushAskToAskMessageTemplate.h
//  LeanplumSDK-iOS
//
//  Created by Mayank Sanganeria on 2/6/20.
//  Copyright © 2020 Leanplum. All rights reserved.
//

#import "LPMessageTemplateProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface LPPushAskToAskMessageTemplate : NSObject <LPMessageTemplateProtocol>

- (void)enableSystemPush;

@end

NS_ASSUME_NONNULL_END
