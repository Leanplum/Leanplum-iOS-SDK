//
//  LPPushAsktoAskMessageTemplate.m
//  LeanplumSDK-iOS
//
//  Created by Mayank Sanganeria on 2/6/20.
//  Copyright © 2020 Leanplum. All rights reserved.
//

#import "LPPushAsktoAskMessageTemplate.h"

@implementation LPPushAsktoAskMessageTemplate

-(void)defineActionWithContexts:(NSMutableArray *)contexts {
    [super defineActionWithContexts:contexts];

    // might be common with others
    UIColor *defaultButtonTextColor = [UIColor colorWithRed:0 green:0.478431 blue:1 alpha:1];
    [Leanplum defineAction:LPMT_PUSH_ASK_TO_ASK
                    ofKind:kLeanplumActionKindMessage | kLeanplumActionKindAction
             withArguments:@[
                 [LPActionArg argNamed:LPMT_ARG_TITLE_TEXT withString:APP_NAME],
                 [LPActionArg argNamed:LPMT_ARG_TITLE_COLOR
                             withColor:[UIColor blackColor]],
                 [LPActionArg argNamed:LPMT_ARG_MESSAGE_TEXT
                            withString:LPMT_DEFAULT_ASK_TO_ASK_MESSAGE],
                 [LPActionArg argNamed:LPMT_ARG_MESSAGE_COLOR
                             withColor:[UIColor blackColor]],
                 [LPActionArg argNamed:LPMT_ARG_BACKGROUND_IMAGE withFile:nil],
                 [LPActionArg argNamed:LPMT_ARG_BACKGROUND_COLOR
                             withColor:[UIColor colorWithWhite:LIGHT_GRAY alpha:1.0]],
                 [LPActionArg argNamed:LPMT_ARG_ACCEPT_BUTTON_TEXT
                            withString:LPMT_DEFAULT_OK_BUTTON_TEXT],
                 [LPActionArg argNamed:LPMT_ARG_ACCEPT_BUTTON_BACKGROUND_COLOR
                             withColor:[UIColor colorWithWhite:LIGHT_GRAY alpha:1.0]],
                 [LPActionArg argNamed:LPMT_ARG_ACCEPT_BUTTON_TEXT_COLOR
                             withColor:defaultButtonTextColor],
                 [LPActionArg argNamed:LPMT_ARG_CANCEL_ACTION withAction:nil],
                 [LPActionArg argNamed:LPMT_ARG_CANCEL_BUTTON_TEXT
                            withString:LPMT_DEFAULT_LATER_BUTTON_TEXT],
                 [LPActionArg argNamed:LPMT_ARG_CANCEL_BUTTON_BACKGROUND_COLOR
                             withColor:[UIColor colorWithWhite:LIGHT_GRAY alpha:1.0]],
                 [LPActionArg argNamed:LPMT_ARG_CANCEL_BUTTON_TEXT_COLOR
                             withColor:[UIColor grayColor]],
                 [LPActionArg argNamed:LPMT_ARG_LAYOUT_WIDTH
                            withNumber:@(LPMT_DEFAULT_CENTER_POPUP_WIDTH)],
                 [LPActionArg argNamed:LPMT_ARG_LAYOUT_HEIGHT
                            withNumber:@(LPMT_DEFAULT_CENTER_POPUP_HEIGHT)]
             ]
             withResponder:^BOOL(LPActionContext *context) {
        if ([Leanplum isPreLeanplumInstall]) {
            NSLog(@"Leanplum: 'Ask to ask' conservatively falls back to just 'ask' for pre-Leanplum installs");
            [self enableSystemPush];
            return NO;
        } else if ([self isPushEnabled]) {
            NSLog(@"Leanplum: Pushes already enabled");
            return NO;
        } else if ([self hasDisabledAskToAsk]) {
            NSLog(@"Leanplum: Already asked to push");
            return NO;
        } else {
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
                NSLog(@"Leanplum: Error in pushAskToAsk: %@\n%@", exception,
                      [exception callStackSymbols]);
                return NO;
            }
        }
    }];
}

@end
