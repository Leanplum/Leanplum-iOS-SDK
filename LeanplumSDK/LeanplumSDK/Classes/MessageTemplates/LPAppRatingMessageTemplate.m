//
//  LPAppRatingMessageTemplate.m
//  LeanplumSDK-iOS
//
//  Created by Mayank Sanganeria on 2/7/20.
//  Copyright © 2020 Leanplum. All rights reserved.
//

#import "LPAppRatingMessageTemplate.h"
#import "LPActionContext.h"

@implementation LPAppRatingMessageTemplate

+(void)defineAction
{
    [Leanplum defineAction:LPMT_APP_RATING_NAME
                    ofKind:kLeanplumActionKindAction
             withArguments:@[]
               withOptions:@{}
            presentHandler:^BOOL(LPActionContext *context) {
        @try {
            LPAppRatingMessageTemplate *appRatingMessageTemplate = [[LPAppRatingMessageTemplate alloc] init];
            
            [appRatingMessageTemplate appStorePrompt];
            
            /**
             * There is no completion handler for the requestReview.
             * No information is returned if the prompt has been shown or not.
             * It could be possible to check if a window is presented by comparing the windows count but this is not reliable.
             *
             * Action is marked as dismissed so the queue can continue executing.
             * The app request is shown on a separate window,
             * so even if an alert message is presented while the App Review is present,
             * it will show underneath and not break the UI.
             *
             * If this behavior is undesired, then dispatch after a delay,
             * to provide some time to the user to rate the app, then dismiss the action.
             */
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [context actionDismissed];
            });
            
            return YES;
        } @catch (NSException *exception) {
            LOG_LP_MESSAGE_EXCEPTION;
        }
        return NO;
    }
            dismissHandler:^BOOL(LPActionContext * _Nonnull context) {
        return NO;
    }];
}

- (void)appStorePrompt
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (NSClassFromString(@"SKStoreReviewController")) {
            if (@available(iOS 14.0, *)) {
                // Find active scene
                __block UIScene *scene;
                [[[UIApplication sharedApplication] connectedScenes] enumerateObjectsUsingBlock:^(UIScene * _Nonnull obj, BOOL * _Nonnull stop) {
                    if (obj.activationState == UISceneActivationStateForegroundActive) {
                        scene = obj;
                        *stop = YES;
                    }
                }];
                // Present using scene
                UIWindowScene *windowScene = (UIWindowScene*)scene;
                if (windowScene) {
                    [SKStoreReviewController requestReviewInScene:windowScene];
                }
            } else if (@available(iOS 10.3, *)) {
                [SKStoreReviewController requestReview];
            }
        }
    });
}

@end
