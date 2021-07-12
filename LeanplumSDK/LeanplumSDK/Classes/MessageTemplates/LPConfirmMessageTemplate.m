//
//  LPConfirmMessageTemplate.m
//  LeanplumSDK-iOS
//
//  Created by Milos Jakovljevic on 15/04/2020.
//  Copyright © 2020 Leanplum. All rights reserved.
//

#import "LPConfirmMessageTemplate.h"
#import "LPActionContext.h"

@implementation LPConfirmMessageTemplate

+ (void)defineAction
{
    BOOL (^responder)(LPActionContext *) = ^(LPActionContext *context) {
        @try {
            LPConfirmMessageTemplate *template = [[LPConfirmMessageTemplate alloc] init];
            UIViewController *alertViewController = [template viewControllerWithContext:context];

            [LPMessageTemplateUtilities presentOverVisible:alertViewController];

            return YES;
        } @catch (NSException *exception) {
            LOG_LP_MESSAGE_EXCEPTION;
            return NO;
        }
    };

    [Leanplum defineAction:LPMT_CONFIRM_NAME
                    ofKind:kLeanplumActionKindMessage | kLeanplumActionKindAction
             withArguments:@[
                 [LPActionArg argNamed:LPMT_ARG_TITLE withString:APP_NAME],
                 [LPActionArg argNamed:LPMT_ARG_MESSAGE withString:LPMT_DEFAULT_CONFIRM_MESSAGE],
                 [LPActionArg argNamed:LPMT_ARG_ACCEPT_TEXT withString:LPMT_DEFAULT_YES_BUTTON_TEXT],
                 [LPActionArg argNamed:LPMT_ARG_CANCEL_TEXT withString:LPMT_DEFAULT_NO_BUTTON_TEXT],
                 [LPActionArg argNamed:LPMT_ARG_ACCEPT_ACTION withAction:nil],
                 [LPActionArg argNamed:LPMT_ARG_CANCEL_ACTION withAction:nil],
             ]
             withResponder:responder];
}

- (UIViewController *)viewControllerWithContext:(LPActionContext *)context
{
    UIAlertController *alertViewController = [UIAlertController alertControllerWithTitle:NSLocalizedString([context stringNamed:LPMT_ARG_TITLE], nil)
                                                                                 message:NSLocalizedString([context stringNamed:LPMT_ARG_MESSAGE], nil)
                                                                          preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *cancel = [UIAlertAction actionWithTitle:NSLocalizedString([context stringNamed:LPMT_ARG_CANCEL_TEXT], nil)
                                                     style:UIAlertActionStyleCancel
                                                   handler:^(UIAlertAction *action) {
        [context runActionNamed:LPMT_ARG_CANCEL_ACTION];
    }];
    [alertViewController addAction:cancel];
    UIAlertAction *accept = [UIAlertAction actionWithTitle:NSLocalizedString([context stringNamed:LPMT_ARG_ACCEPT_TEXT], nil)
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction *action) {
        [context runTrackedActionNamed:LPMT_ARG_ACCEPT_ACTION];
    }];
    [alertViewController addAction:accept];
    return alertViewController;
}

@end
