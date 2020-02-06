//
//  LPInterstitialMessageTemplate.m
//  LeanplumSDK-iOS
//
//  Created by Mayank Sanganeria on 2/6/20.
//  Copyright © 2020 Leanplum. All rights reserved.
//

#import "LPWebInterstitialMessageTemplate.h"
#import "LPConfirmMessageTemplate.h"

@implementation LPWebInterstitialMessageTemplate

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

    [Leanplum defineAction:LPMT_WEB_INTERSTITIAL_NAME
                    ofKind:kLeanplumActionKindMessage | kLeanplumActionKindAction
             withArguments:@[
                 [LPActionArg argNamed:LPMT_ARG_URL withString:LPMT_DEFAULT_URL],
                 [LPActionArg argNamed:LPMT_ARG_URL_CLOSE withString:LPMT_DEFAULT_CLOSE_URL],
                 [LPActionArg argNamed:LPMT_HAS_DISMISS_BUTTON
                              withBool:LPMT_DEFAULT_HAS_DISMISS_BUTTON]]
             withResponder:^BOOL(LPActionContext *context) {
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
    }];
}

@end
