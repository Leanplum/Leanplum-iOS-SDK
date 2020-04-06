//
//  LPWebInterstitialMessageTemplate.m
//  LeanplumSDK-iOS
//
//  Created by Milos Jakovljevic on 06/04/2020.
//  Copyright © 2020 Leanplum. All rights reserved.
//

#import "LPWebInterstitialMessageTemplate.h"
#import "LPWebInterstitialViewController.h"

@implementation LPWebInterstitialMessageTemplate

@synthesize context = _context;

+ (void)defineAction
{
    BOOL (^webMessageResponder)(LPActionContext *) = ^(LPActionContext *context) {
        @try {
            NSBundle *bundle = [NSBundle bundleForClass:[Leanplum class]];
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"WebInterstitial" bundle:bundle];

            LPWebInterstitialViewController *viewController = (LPWebInterstitialViewController *) ([storyboard instantiateInitialViewController]);
            viewController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
            viewController.context = context;

            UIViewController *rootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
            [rootViewController presentViewController:viewController animated:YES completion:nil];

            return YES;
        } @catch (NSException *exception) {
            LOG_LP_MESSAGE_EXCEPTION;
            return NO;
        }
    };
    [Leanplum defineAction:LPMT_WEB_INTERSTITIAL_NAME
                    ofKind:kLeanplumActionKindMessage | kLeanplumActionKindAction
             withArguments:@[
                 [LPActionArg argNamed:LPMT_ARG_URL withString:LPMT_DEFAULT_URL],
                 [LPActionArg argNamed:LPMT_ARG_URL_CLOSE withString:LPMT_DEFAULT_CLOSE_URL],
                 [LPActionArg argNamed:LPMT_HAS_DISMISS_BUTTON
                              withBool:LPMT_DEFAULT_HAS_DISMISS_BUTTON]]
             withResponder:webMessageResponder];
}

@end
