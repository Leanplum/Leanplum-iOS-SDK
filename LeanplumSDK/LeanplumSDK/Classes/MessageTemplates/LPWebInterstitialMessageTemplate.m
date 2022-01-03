//
//  LPWebInterstitialMessageTemplate.m
//  LeanplumSDK-iOS
//
//  Created by Milos Jakovljevic on 06/04/2020.
//  Copyright © 2020 Leanplum. All rights reserved.
//

#import "LPWebInterstitialMessageTemplate.h"
#import "LPActionContext.h"

@implementation LPWebInterstitialMessageTemplate

+ (void)defineAction
{
    BOOL (^presentHandler)(LPActionContext *) = ^(LPActionContext *context) {
         @try {
             LPWebInterstitialMessageTemplate *template = [[LPWebInterstitialMessageTemplate alloc] init];
             UIViewController *viewController = [template viewControllerWithContext:context];

             [LPMessageTemplateUtilities presentOverVisible:viewController];
             return YES;
         } @catch (NSException *exception) {
             LOG_LP_MESSAGE_EXCEPTION;
             return NO;
         }
     };
    [Leanplum defineAction:LPMT_WEB_INTERSTITIAL_NAME
                    ofKind:kLeanplumActionKindAction | kLeanplumActionKindMessage
             withArguments:@[
        [LPActionArg argNamed:LPMT_ARG_URL withString:LPMT_DEFAULT_URL],
        [LPActionArg argNamed:LPMT_ARG_URL_CLOSE withString:LPMT_DEFAULT_CLOSE_URL],
        [LPActionArg argNamed:LPMT_HAS_DISMISS_BUTTON withBool:LPMT_DEFAULT_HAS_DISMISS_BUTTON]
    ]
               withOptions:@{}
            presentHandler:presentHandler
            dismissHandler:nil];
}

- (UIViewController *)viewControllerWithContext:(LPActionContext *)context
{
    LPWebInterstitialViewController *viewController = [LPWebInterstitialViewController instantiateFromStoryboard];
    viewController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    viewController.context = context;
    return viewController;
}

@end
