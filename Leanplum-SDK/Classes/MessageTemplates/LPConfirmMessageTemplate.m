//
//  LPConfirmMessageTemplate.m
//  LeanplumSDK-iOS
//
//  Created by Mayank Sanganeria on 1/27/20.
//  Copyright © 2020 Leanplum. All rights reserved.
//

#import "LPConfirmMessageTemplate.h"
#import "Leanplum.h"

@implementation LPConfirmMessageTemplate

-(void)defineActionWithContexts:(NSMutableArray *)contexts {
    [super defineActionWithContexts:contexts];
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
                     if (NSClassFromString(@"UIAlertController")) {
                         UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString([context stringNamed:LPMT_ARG_TITLE], nil) message:NSLocalizedString([context stringNamed:LPMT_ARG_MESSAGE], nil) preferredStyle:UIAlertControllerStyleAlert];
                         UIAlertAction *cancel = [UIAlertAction actionWithTitle:NSLocalizedString([context stringNamed:LPMT_ARG_CANCEL_TEXT], nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
                             [self alertDismissedWithButtonIndex:0];
                         }];
                         [alert addAction:cancel];
                         UIAlertAction *accept = [UIAlertAction actionWithTitle:NSLocalizedString([context stringNamed:LPMT_ARG_ACCEPT_TEXT], nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                             [self alertDismissedWithButtonIndex:1];
                         }];
                         [alert addAction:accept];

                         [[self visibleViewController]
                          presentViewController:alert animated:YES completion:nil];
                     } else
                     {
                         UIAlertView *alert = [[UIAlertView alloc]
                                               initWithTitle:NSLocalizedString([context stringNamed:LPMT_ARG_TITLE], nil)
                                               message:NSLocalizedString([context stringNamed:LPMT_ARG_MESSAGE], nil)
                                               delegate:self
                                               cancelButtonTitle:NSLocalizedString([context stringNamed:LPMT_ARG_CANCEL_TEXT], nil)
                                               otherButtonTitles:NSLocalizedString([context stringNamed:LPMT_ARG_ACCEPT_TEXT], nil),nil];
                         [alert show];
                     }
                     [self.contexts addObject:context];
                     return YES;
                 }
                 @catch (NSException *exception) {
                     LOG_LP_MESSAGE_EXCEPTION;
                     return NO;
                 }
             }];
    
}

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
