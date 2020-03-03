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

                         [[self visibleViewController]
                          presentViewController:[self viewControllerWithContext:context] animated:YES completion:nil];
                     [self.contexts addObject:context];
                     return YES;
                 }
                 @catch (NSException *exception) {
                     LOG_LP_MESSAGE_EXCEPTION;
                     return NO;
                 }
             }];
    
}

-(UIViewController *)viewControllerWithContext:(LPActionContext *)context {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString([context stringNamed:LPMT_ARG_TITLE], nil) message:NSLocalizedString([context stringNamed:LPMT_ARG_MESSAGE], nil) preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:NSLocalizedString([context stringNamed:LPMT_ARG_CANCEL_TEXT], nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        [self alertDismissedWithButtonIndex:0];
    }];
    [alert addAction:cancel];
    UIAlertAction *accept = [UIAlertAction actionWithTitle:NSLocalizedString([context stringNamed:LPMT_ARG_ACCEPT_TEXT], nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self alertDismissedWithButtonIndex:1];
    }];
    [alert addAction:accept];
    return alert;
}
@end
