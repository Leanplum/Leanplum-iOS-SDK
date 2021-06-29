//
//  LPPushAskToAskMessageTemplate.m
//  LeanplumSDK-iOS
//
//  Created by Mayank Sanganeria on 2/6/20.
//  Copyright © 2020 Leanplum. All rights reserved.
//

#import "LPPushAskToAskMessageTemplate.h"
#import "LPPushMessageTemplate.h"
#import "LPActionContext.h"

@implementation LPPushAskToAskMessageTemplate

@synthesize context;

+(void)defineAction
{
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
        if ([context hasMissingFiles]) {
            return NO;
        }

        @try {            
            LPPushAskToAskMessageTemplate *template = [[LPPushAskToAskMessageTemplate alloc] init];
            template.context = context;
            if ([template shouldShowPushMessage]) {
                [template showPrePushMessage];
                return YES;
            } else {
                return NO;
            }
        } @catch (NSException *exception) {
            LPLog(LPError, @"PushAskToAsk: %@\n%@", exception, [exception callStackSymbols]);
            return NO;
        }
    }];
}

- (LPPopupViewController *)viewControllerWithContext:(LPActionContext *)context
{
    LPPopupViewController *viewController = [LPPopupViewController instantiateFromStoryboard];
    viewController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    viewController.context = context;
    viewController.shouldShowCancelButton = YES;
    __strong __typeof__(self) strongSelf = self;
    viewController.acceptCompletionBlock = ^{
        __typeof__(self) weakSelf = strongSelf;
        [weakSelf showNativePushPrompt];
    };
    return viewController;
}

-(void)showPrePushMessage
{
    UIViewController *viewController = [self viewControllerWithContext:self.context];

    [LPMessageTemplateUtilities presentOverVisible:viewController];
}

@end
