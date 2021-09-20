//
//  LPBaseMessageTemplate.h
//  LeanplumSDK-iOS
//
//  Created by Mayank Sanganeria on 1/27/20.
//  Copyright © 2020 Leanplum. All rights reserved.
//

#import "LPMessageTemplateConstants.h"
#import "LPMessageTemplateUtilities.h"

@class LPActionContext;

NS_ASSUME_NONNULL_BEGIN

@protocol LPMessageTemplateProtocol

+ (void)defineAction;

@optional
@property (nonatomic, strong) LPActionContext *context;
- (UIViewController *)viewControllerWithContext:(LPActionContext *) context;
@end

NS_ASSUME_NONNULL_END
