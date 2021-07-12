//
//  LPRegisterForPushMessageTemplate.h
//  LeanplumSDK-iOS
//
//  Created by Mayank Sanganeria on 2/7/20.
//  Copyright © 2020 Leanplum. All rights reserved.
//

#import "LPMessageTemplateProtocol.h"
#import "LPPushMessageTemplate.h"

NS_ASSUME_NONNULL_BEGIN

@interface LPRegisterForPushMessageTemplate : LPPushMessageTemplate <LPMessageTemplateProtocol>

@end

NS_ASSUME_NONNULL_END
