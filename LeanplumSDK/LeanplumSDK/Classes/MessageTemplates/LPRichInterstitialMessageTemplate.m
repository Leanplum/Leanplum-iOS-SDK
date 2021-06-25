//
//  LPRichInterstitialMessageTemplate.m
//  LeanplumSDK-iOS
//
//  Created by Milos Jakovljevic on 06/04/2020.
//  Copyright © 2020 Leanplum. All rights reserved.
//

#import "LPRichInterstitialMessageTemplate.h"
#import "LPActionContext.h"

@implementation LPRichInterstitialMessageTemplate

+ (void)defineAction
{
    BOOL (^responder)(LPActionContext *) = ^(LPActionContext *context) {
        if ([context hasMissingFiles]) {
            return NO;
        }

        @try {
            LPRichInterstitialMessageTemplate *template = [[LPRichInterstitialMessageTemplate alloc] init];
            UIViewController *viewController = [template viewControllerWithContext:context];

            [LPMessageTemplateUtilities presentOverVisible:viewController];
            return YES;
        } @catch (NSException *exception) {
            LOG_LP_MESSAGE_EXCEPTION;
            return NO;
        }
    };
    [Leanplum defineAction:LPMT_HTML_NAME
                    ofKind:kLeanplumActionKindMessage | kLeanplumActionKindAction
             withArguments:@[
                 [LPActionArg argNamed:LPMT_ARG_URL_CLOSE withString:LPMT_DEFAULT_CLOSE_URL],
                 [LPActionArg argNamed:LPMT_ARG_URL_OPEN withString:LPMT_DEFAULT_OPEN_URL],
                 [LPActionArg argNamed:LPMT_ARG_URL_TRACK withString:LPMT_DEFAULT_TRACK_URL],
                 [LPActionArg argNamed:LPMT_ARG_URL_ACTION withString:LPMT_DEFAULT_ACTION_URL],
                 [LPActionArg argNamed:LPMT_ARG_URL_TRACK_ACTION withString:LPMT_DEFAULT_TRACK_ACTION_URL],
                 [LPActionArg argNamed:LPMT_ARG_HTML_ALIGN withString:LPMT_ARG_HTML_ALIGN_TOP],
                 [LPActionArg argNamed:LPMT_ARG_HTML_HEIGHT withNumber:@0],
                 [LPActionArg argNamed:LPMT_ARG_HTML_WIDTH withString:@"100%"],
                 [LPActionArg argNamed:LPMT_ARG_HTML_TAP_OUTSIDE_TO_CLOSE withBool:NO],
                 [LPActionArg argNamed:LPMT_HAS_DISMISS_BUTTON withBool:NO],
                 [LPActionArg argNamed:LPMT_ARG_HTML_TEMPLATE withFile:nil]]
             withResponder:responder];
}

- (UIViewController *)viewControllerWithContext:(LPActionContext *)context
{
    LPWebInterstitialViewController *viewController = [LPWebInterstitialViewController instantiateFromStoryboard];
    viewController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    viewController.context = context;
    return viewController;
}

@end
