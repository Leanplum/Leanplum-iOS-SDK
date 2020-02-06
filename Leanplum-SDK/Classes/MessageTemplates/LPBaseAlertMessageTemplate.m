//
//  LPAlertBaseMessageTemplate.m
//  LeanplumSDK-iOS
//
//  Created by Mayank Sanganeria on 2/6/20.
//  Copyright © 2020 Leanplum. All rights reserved.
//

#import "LPBaseAlertMessageTemplate.h"

@implementation LPBaseAlertMessageTemplate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    [self alertDismissedWithButtonIndex:buttonIndex];
}

- (void)alertDismissedWithButtonIndex:(NSInteger)buttonIndex
{
    LPActionContext *context = self.contexts.lastObject;
    @try {
        [self.contexts removeLastObject];

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
