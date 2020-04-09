//
//  LPBaseMessageTemplate.h
//  LeanplumSDK-iOS
//
//  Created by Mayank Sanganeria on 1/27/20.
//  Copyright © 2020 Leanplum. All rights reserved.
//

#import "Leanplum.h"
#import "LPMessageTemplateConstants.h"
#import "LPApplication+Extensions.h"

NS_ASSUME_NONNULL_BEGIN

@protocol LPMessageTemplateProtocol

@property (nonatomic, strong) LPActionContext *context;

+ (void)defineAction;

@end

NS_ASSUME_NONNULL_END
