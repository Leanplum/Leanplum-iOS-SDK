//
//  LPAlertMessageTemplate.m
//  LeanplumSDK-iOS
//
//  Created by Milos Jakovljevic on 06/04/2020.
//  Copyright © 2020 Leanplum. All rights reserved.
//

#import "LPAlertMessageTemplate.h"

@implementation LPAlertMessageTemplate

@synthesize context;

+ (void)defineAction
{
    // Alert
    [Leanplum defineAction:LPMT_ALERT_NAME
                    ofKind:kLeanplumActionKindMessage | kLeanplumActionKindAction
             withArguments:@[
                 [LPActionArg argNamed:LPMT_ARG_TITLE withString:APP_NAME],
                 [LPActionArg argNamed:LPMT_ARG_MESSAGE withString:LPMT_DEFAULT_ALERT_MESSAGE],
                 [LPActionArg argNamed:LPMT_ARG_DISMISS_TEXT withString:LPMT_DEFAULT_OK_BUTTON_TEXT],
                 [LPActionArg argNamed:LPMT_ARG_DISMISS_ACTION withAction:nil]
             ]
             withResponder:^BOOL(LPActionContext *context) {
        @try {
            UIAlertController *alertViewController = [UIAlertController alertControllerWithTitle:NSLocalizedString([context stringNamed:LPMT_ARG_TITLE], nil)
                                                                                         message:NSLocalizedString([context stringNamed:LPMT_ARG_MESSAGE], nil)
                                                                                  preferredStyle:UIAlertControllerStyleAlert];

            UIAlertAction *dismiss = [UIAlertAction actionWithTitle:NSLocalizedString([context stringNamed:LPMT_ARG_DISMISS_TEXT], nil)
                                                              style:UIAlertActionStyleDefault
                                                            handler:^(UIAlertAction *action) {
                [context runActionNamed:LPMT_ARG_DISMISS_ACTION];
            }];
            [alertViewController addAction:dismiss];

            [LPMessageTemplateUtilities presentOverVisible:alertViewController];
            return YES;
        }
        @catch (NSException *exception) {
            LOG_LP_MESSAGE_EXCEPTION;
            return NO;
        }
    }];

    // Confirm
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
             withResponder:^BOOL(LPActionContext *context) {
        @try {
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

            [LPMessageTemplateUtilities presentOverVisible:alertViewController];
            return YES;
        }
        @catch (NSException *exception) {
            LOG_LP_MESSAGE_EXCEPTION;
            return NO;
        }
    }];
}

@end
