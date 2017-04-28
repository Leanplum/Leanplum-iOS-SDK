//
//  LPUIAlert.m
//  Shows an alert with a callback block.
//
//  Created by Ryan Maxwell on 29/08/13.
//  Copyright (c) 2013 Ryan Maxwell. All rights reserved.
//  Copyright (c) 2015 Leanplum, Inc. All rights reserved.
//

#import "LPUIAlert.h"
#import "Constants.h"

@implementation LPUIAlert

+ (void)showWithTitle:(NSString *)title
              message:(NSString *)message
    cancelButtonTitle:(NSString *)cancelButtonTitle
    otherButtonTitles:(NSArray *)otherButtonTitles
                block:(LeanplumUIAlertCompletionBlock)block
{
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
    if (NSClassFromString(@"UIAlertController")) {
        UIAlertController *alert =
            [UIAlertController alertControllerWithTitle:title
                                                message:message
                                         preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *action = [UIAlertAction actionWithTitle:cancelButtonTitle
                                                         style:[otherButtonTitles count] ? UIAlertActionStyleCancel : UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction *action) {
                                                           if (block) {
                                                               block(0);
                                                           }
                                                       }];
        [alert addAction:action];
        
        int currentIndex = 0;
        for (NSString *buttonTitle in otherButtonTitles) {
            int buttonIndex = ++currentIndex;
            UIAlertAction *action = [UIAlertAction actionWithTitle:buttonTitle
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction *action) {
                                                               if (block) {
                                                                   block(buttonIndex);
                                                               }
                                                           }];
            [alert addAction:action];
        }

        [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alert
                                                                                     animated:YES
                                                                                   completion:nil];
    } else
#endif
    {
#if LP_NOT_TV
        LPUIAlertView *alertView = [[LPUIAlertView alloc] initWithTitle:title
                                                                message:message
                                                               delegate:nil
                                                      cancelButtonTitle:cancelButtonTitle
                                                      otherButtonTitles:nil];
        alertView.delegate = alertView;
        for (NSString *buttonTitle in otherButtonTitles) {
            [alertView addButtonWithTitle:buttonTitle];
        }
        if (block) {
            alertView->block = block;
        }
        [alertView show];
#endif
    }
}

@end

#if LP_NOT_TV
@implementation LPUIAlertView

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    LeanplumUIAlertCompletionBlock completion = ((LPUIAlertView*) alertView)->block;
    if (completion)
    {
        completion(buttonIndex);
    }
}

@end
#endif
