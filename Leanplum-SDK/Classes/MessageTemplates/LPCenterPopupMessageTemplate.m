//
//  LPCenterPopupMessageTemplate.m
//  LeanplumSDK-iOS
//
//  Created by Mayank Sanganeria on 2/7/20.
//  Copyright © 2020 Leanplum. All rights reserved.
//

#import "LPCenterPopupMessageTemplate.h"

@implementation LPCenterPopupMessageTemplate

-(void)defineActionWithContexts:(NSMutableArray *)contexts {
    [super defineActionWithContexts:contexts];

    // might be common with others
    UIColor *defaultButtonTextColor = [UIColor colorWithRed:0 green:0.478431 blue:1 alpha:1];
    BOOL (^messageResponder)(LPActionContext *) = ^(LPActionContext *context) {
        if ([context hasMissingFiles]) {
            return NO;
        }

        @try {
            [self closePopupWithAnimation:NO];
            [self.contexts addObject:context];
            [self showPopup];
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
                 [LPActionArg argNamed:LPMT_ARG_ACCEPT_BUTTON_TEXT_COLOR withColor:defaultButtonTextColor],
                 [LPActionArg argNamed:LPMT_ARG_ACCEPT_ACTION withAction:nil],
                 [LPActionArg argNamed:LPMT_ARG_LAYOUT_WIDTH withNumber:@(LPMT_DEFAULT_CENTER_POPUP_WIDTH)],
                 [LPActionArg argNamed:LPMT_ARG_LAYOUT_HEIGHT withNumber:@(LPMT_DEFAULT_CENTER_POPUP_HEIGHT)]
             ]
             withResponder:messageResponder];
    
}
@end
