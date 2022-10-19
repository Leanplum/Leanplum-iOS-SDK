//
//  LPRichInterstitialMessageTemplate.m
//  LeanplumSDK-iOS
//
//  Created by Milos Jakovljevic on 06/04/2020.
//  Copyright © 2022 Leanplum. All rights reserved.
//

#import "LPRichInterstitialMessageTemplate.h"
#import "LPActionContext.h"

@implementation LPRichInterstitialMessageTemplate

+ (void)defineAction
{
    __block UIViewController *viewController = NULL;
    
    BOOL (^presentHandler)(LPActionContext *) = ^(LPActionContext *context) {
        if ([context hasMissingFiles]) {
            return NO;
        }

        @try {
            LPRichInterstitialMessageTemplate *template = [[LPRichInterstitialMessageTemplate alloc] init];
            viewController = [template viewControllerWithContext:context];
            
            [LPMessageTemplateUtilities presentOverVisible:viewController];
            
            return YES;
        } @catch (NSException *exception) {
            LOG_LP_MESSAGE_EXCEPTION;
            return NO;
        }
    };
    [Leanplum defineAction:LPMT_HTML_NAME
                    ofKind:kLeanplumActionKindAction | kLeanplumActionKindMessage
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
        [LPActionArg argNamed:LPMT_ARG_HTML_TEMPLATE withFile:nil]
    ]
               withOptions:@{}
            presentHandler:presentHandler
            dismissHandler:^BOOL(LPActionContext * _Nonnull context) {
        [viewController dismissViewControllerAnimated:YES completion:nil];
        return YES;
    }];

}

- (UIViewController *)viewControllerWithContext:(LPActionContext *)context
{
    LPWebInterstitialViewController *viewController = [LPWebInterstitialViewController instantiateFromStoryboard];
    if ([LPRichInterstitialMessageTemplate isBannerTemplate:context]) {
        viewController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    } else {
        viewController.modalPresentationStyle = UIModalPresentationOverFullScreen;
    }
    viewController.context = context;
    return viewController;
}

+ (BOOL)isBannerTemplate:(LPActionContext *)context
{
    CGFloat height = [[context numberNamed:LPMT_ARG_HTML_HEIGHT] doubleValue];
    return height > 0;
}

@end
