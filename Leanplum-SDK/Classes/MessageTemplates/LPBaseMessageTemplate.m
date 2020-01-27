//
//  LPBaseMessageTemplate.m
//  LeanplumSDK-iOS
//
//  Created by Mayank Sanganeria on 1/27/20.
//  Copyright © 2020 Leanplum. All rights reserved.
//

#import "LPBaseMessageTemplate.h"

@implementation LPBaseMessageTemplate

-(void)defineActionWithContexts:(NSMutableArray *)contexts {
    self.contexts = contexts;
}

- (UIViewController *)visibleViewController
{
    UIViewController *topController = [UIApplication sharedApplication].keyWindow.rootViewController;
    while (topController.presentedViewController) {
        topController = topController.presentedViewController;
    }
    return topController;
}

#pragma mark Alert and Confirm Logic

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    [self alertDismissedWithButtonIndex:buttonIndex];
}

- (void)alertDismissedWithButtonIndex:(NSInteger)buttonIndex
{
    LPActionContext *context = _contexts.lastObject;
    @try {
        [_contexts removeLastObject];

        if ([context.actionName isEqualToString:LPMT_ALERT_NAME]) {
            [context runActionNamed:LPMT_ARG_DISMISS_ACTION];
        } else {
            if (buttonIndex == 1) {
                [context runTrackedActionNamed:LPMT_ARG_ACCEPT_ACTION];
            } else {
                [context runActionNamed:LPMT_ARG_CANCEL_ACTION];
            }
        }
    }
    @catch (NSException *exception) {
        LOG_LP_MESSAGE_EXCEPTION;
    }
}

@end
