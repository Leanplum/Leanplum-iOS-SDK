//
//  LPCenterPopupMessageTemplate.h
//  LeanplumSDK-iOS
//
//  Created by Milos Jakovljevic on 06/04/2020.
//  Copyright © 2020 Leanplum. All rights reserved.
//

#import "LPMessageTemplateProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface LPCenterPopupMessageTemplate : NSObject <LPMessageTemplateProtocol>

- (LPPopupViewController *)viewControllerWith:(LPActionContext *) context;

@end

NS_ASSUME_NONNULL_END
