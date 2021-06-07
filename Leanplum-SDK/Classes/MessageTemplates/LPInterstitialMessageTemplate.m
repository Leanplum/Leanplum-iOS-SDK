//
//  LPInterstitialMessageTemplate.m
//  LeanplumSDK-iOS
//
//  Created by Milos Jakovljevic on 06/04/2020.
//  Copyright © 2020 Leanplum. All rights reserved.
//

#import "LPInterstitialMessageTemplate.h"
#import "LPActionContext.h"

@implementation LPInterstitialMessageTemplate

+ (void)defineAction
{
    BOOL (^responder)(LPActionContext *) = ^(LPActionContext *context) {
        if ([context hasMissingFiles]) {
            return NO;
        }

        @try {
            LPInterstitialMessageTemplate *template = [[LPInterstitialMessageTemplate alloc] init];
            UIViewController *viewController = [template viewControllerWithContext:context];

            [LPMessageTemplateUtilities presentOverVisible:viewController];

            return YES;
        } @catch (NSException *exception) {
            LOG_LP_MESSAGE_EXCEPTION;
            return NO;
        }
    };

    [Leanplum defineAction:LPMT_INTERSTITIAL_NAME
                    ofKind:kLeanplumActionKindMessage | kLeanplumActionKindAction
             withArguments:@[
                 [LPActionArg argNamed:LPMT_ARG_TITLE_TEXT withString:APP_NAME],
                 [LPActionArg argNamed:LPMT_ARG_TITLE_COLOR withColor:[UIColor blackColor]],
                 [LPActionArg argNamed:LPMT_ARG_MESSAGE_TEXT withString:LPMT_DEFAULT_INTERSTITIAL_MESSAGE],
                 [LPActionArg argNamed:LPMT_ARG_MESSAGE_COLOR withColor:[UIColor blackColor]],
                 [LPActionArg argNamed:LPMT_ARG_BACKGROUND_IMAGE withFile:nil],
                 [LPActionArg argNamed:LPMT_ARG_BACKGROUND_COLOR withColor:[UIColor whiteColor]],
                 [LPActionArg argNamed:LPMT_ARG_ACCEPT_BUTTON_TEXT withString:LPMT_DEFAULT_OK_BUTTON_TEXT],
                 [LPActionArg argNamed:LPMT_ARG_ACCEPT_BUTTON_BACKGROUND_COLOR withColor:[UIColor whiteColor]],
                 [LPActionArg argNamed:LPMT_ARG_ACCEPT_BUTTON_TEXT_COLOR withColor:UIColor.blueColor],
                 [LPActionArg argNamed:LPMT_ARG_ACCEPT_ACTION withAction:nil]
             ]
             withResponder:responder];
}

-(UIViewController *)viewControllerWithContext:(LPActionContext *)context
{
    LPInterstitialViewController *viewController = [LPInterstitialViewController instantiateFromStoryboard];
    viewController.modalPresentationStyle = UIModalPresentationFullScreen;
    viewController.context = context;
    return viewController;
}

@end
