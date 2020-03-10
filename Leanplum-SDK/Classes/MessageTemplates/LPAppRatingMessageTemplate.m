//
//  LPAppRatingMessageTemplate.m
//  LeanplumSDK-iOS
//
//  Created by Mayank Sanganeria on 2/7/20.
//  Copyright © 2020 Leanplum. All rights reserved.
//

#import "LPAppRatingMessageTemplate.h"

@implementation LPAppRatingMessageTemplate

-(void)defineActionWithContexts:(NSMutableArray *)contexts {
    [super defineActionWithContexts:contexts];
    
    [Leanplum defineAction:LPMT_APP_RATING_NAME
                    ofKind:kLeanplumActionKindAction withArguments:@[]
             withResponder:^BOOL(LPActionContext *context) {
        @try {
            [self appStorePrompt];
            return YES;
        }
        @catch (NSException *exception) {
            LOG_LP_MESSAGE_EXCEPTION;
        }
        return NO;
    }];
}

- (void)appStorePrompt
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (NSClassFromString(@"SKStoreReviewController")) {
            if (@available(iOS 10.3, *)) {
                [SKStoreReviewController requestReview];
            } else {
                // Fallback on earlier versions
            }
        }
    });
}

@end
