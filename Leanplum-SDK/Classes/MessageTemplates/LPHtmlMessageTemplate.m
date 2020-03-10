//
//  LPHtmlMessageTemplate.m
//  LeanplumSDK-iOS
//
//  Created by Mayank Sanganeria on 2/7/20.
//  Copyright © 2020 Leanplum. All rights reserved.
//

#import "LPHtmlMessageTemplate.h"

@implementation LPHtmlMessageTemplate

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
    [Leanplum defineAction:LPMT_HTML_NAME
                    ofKind:kLeanplumActionKindMessage | kLeanplumActionKindAction
             withArguments:@[
                 [LPActionArg argNamed:LPMT_ARG_URL_CLOSE withString:LPMT_DEFAULT_CLOSE_URL],
                 [LPActionArg argNamed:LPMT_ARG_URL_OPEN withString:LPMT_DEFAULT_OPEN_URL],
                 [LPActionArg argNamed:LPMT_ARG_URL_TRACK withString:LPMT_DEFAULT_TRACK_URL],
                 [LPActionArg argNamed:LPMT_ARG_URL_ACTION withString:LPMT_DEFAULT_ACTION_URL],
                 [LPActionArg argNamed:LPMT_ARG_URL_TRACK_ACTION
                            withString:LPMT_DEFAULT_TRACK_ACTION_URL],
                 [LPActionArg argNamed:LPMT_ARG_HTML_ALIGN withString:LPMT_ARG_HTML_ALIGN_TOP],
                 [LPActionArg argNamed:LPMT_ARG_HTML_HEIGHT withNumber:@0],
                 [LPActionArg argNamed:LPMT_ARG_HTML_WIDTH withString:@"100%"],
                 [LPActionArg argNamed:LPMT_ARG_HTML_Y_OFFSET withString:@"0px"],
                 [LPActionArg argNamed:LPMT_ARG_HTML_TAP_OUTSIDE_TO_CLOSE withBool:NO],
                 [LPActionArg argNamed:LPMT_HAS_DISMISS_BUTTON withBool:NO],
                 [LPActionArg argNamed:LPMT_ARG_HTML_TEMPLATE withFile:nil]]
             withResponder:messageResponder];
}

@end
