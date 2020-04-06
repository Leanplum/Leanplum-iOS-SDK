//
//  LPCenterPopupMessageTemplate.m
//  LeanplumSDK-iOS
//
//  Created by Milos Jakovljevic on 06/04/2020.
//  Copyright © 2020 Leanplum. All rights reserved.
//

#import "LPCenterPopupMessageTemplate.h"
#import "LPPopupViewController.h"

@implementation LPCenterPopupMessageTemplate

@synthesize context = _context;

+ (void)defineAction
{
    BOOL (^messageResponder)(LPActionContext *) = ^(LPActionContext *context) {
        if ([context hasMissingFiles]) {
            return NO;
        }

        @try {
            NSBundle *bundle = [NSBundle bundleForClass:[Leanplum class]];
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Popup" bundle:bundle];

            LPPopupViewController *viewController = (LPPopupViewController *) ([storyboard instantiateInitialViewController]);
            viewController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
            viewController.context = context;

            UIViewController *rootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
            [rootViewController presentViewController:viewController animated:YES completion:nil];
            return YES;
        }
        @catch (NSException *exception) {
            LOG_LP_MESSAGE_EXCEPTION;
            return NO;
        }
    };
    [Leanplum defineAction:LPMT_CENTER_POPUP_NAME
                    ofKind:kLeanplumActionKindMessage | kLeanplumActionKindAction
             withArguments:@[
                 [LPActionArg argNamed:LPMT_ARG_TITLE_TEXT withString:APP_NAME],
                 [LPActionArg argNamed:LPMT_ARG_TITLE_COLOR withColor:[UIColor blackColor]],
                 [LPActionArg argNamed:LPMT_ARG_MESSAGE_TEXT withString:LPMT_DEFAULT_POPUP_MESSAGE],
                 [LPActionArg argNamed:LPMT_ARG_MESSAGE_COLOR withColor:[UIColor blackColor]],
                 [LPActionArg argNamed:LPMT_ARG_BACKGROUND_IMAGE withFile:nil],
                 [LPActionArg argNamed:LPMT_ARG_BACKGROUND_COLOR withColor:[UIColor whiteColor]],
                 [LPActionArg argNamed:LPMT_ARG_ACCEPT_BUTTON_TEXT withString:LPMT_DEFAULT_OK_BUTTON_TEXT],
                 [LPActionArg argNamed:LPMT_ARG_ACCEPT_BUTTON_BACKGROUND_COLOR withColor:[UIColor whiteColor]],
                 [LPActionArg argNamed:LPMT_ARG_ACCEPT_BUTTON_TEXT_COLOR withColor:UIColor.blueColor],
                 [LPActionArg argNamed:LPMT_ARG_ACCEPT_ACTION withAction:nil],
                 [LPActionArg argNamed:LPMT_ARG_LAYOUT_WIDTH withNumber:@(LPMT_DEFAULT_CENTER_POPUP_WIDTH)],
                 [LPActionArg argNamed:LPMT_ARG_LAYOUT_HEIGHT withNumber:@(LPMT_DEFAULT_CENTER_POPUP_HEIGHT)]
             ]
             withResponder:messageResponder];
}

@end
