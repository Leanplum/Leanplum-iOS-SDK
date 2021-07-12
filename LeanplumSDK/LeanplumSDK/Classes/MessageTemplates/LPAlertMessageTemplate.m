//
//  LPAlertMessageTemplate.m
//  LeanplumSDK-iOS
//
//  Created by Milos Jakovljevic on 06/04/2020.
//  Copyright © 2020 Leanplum. All rights reserved.
//

#import "LPAlertMessageTemplate.h"
#import "LPActionContext.h"

@implementation LPAlertMessageTemplate

+ (void)defineAction
{
    BOOL (^responder)(LPActionContext *) = ^(LPActionContext *context) {
        @try {
            LPAlertMessageTemplate *template = [[LPAlertMessageTemplate alloc] init];
            UIViewController *alertViewController = [template viewControllerWithContext:context];

            [LPMessageTemplateUtilities presentOverVisible:alertViewController];
            return YES;
        } @catch (NSException *exception) {
            LOG_LP_MESSAGE_EXCEPTION;
            return NO;
        }
    };

    [Leanplum defineAction:LPMT_ALERT_NAME
                    ofKind:kLeanplumActionKindMessage | kLeanplumActionKindAction
             withArguments:@[
                 [LPActionArg argNamed:LPMT_ARG_TITLE withString:APP_NAME],
                 [LPActionArg argNamed:LPMT_ARG_MESSAGE withString:LPMT_DEFAULT_ALERT_MESSAGE],
                 [LPActionArg argNamed:LPMT_ARG_DISMISS_TEXT withString:LPMT_DEFAULT_OK_BUTTON_TEXT],
                 [LPActionArg argNamed:LPMT_ARG_DISMISS_ACTION withAction:nil]
             ]
             withResponder:responder];
}

- (UIViewController *)viewControllerWithContext:(LPActionContext *)context
{
    UIAlertController *alertViewController = [UIAlertController alertControllerWithTitle:NSLocalizedString([context stringNamed:LPMT_ARG_TITLE], nil)
                                                                                 message:NSLocalizedString([context stringNamed:LPMT_ARG_MESSAGE], nil)
                                                                          preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *dismiss = [UIAlertAction actionWithTitle:NSLocalizedString([context stringNamed:LPMT_ARG_DISMISS_TEXT], nil)
                                                      style:UIAlertActionStyleDefault
                                                    handler:^(UIAlertAction *action) {
        [context runActionNamed:LPMT_ARG_DISMISS_ACTION];
    }];
    [alertViewController addAction:dismiss];
    return alertViewController;
}

@end
