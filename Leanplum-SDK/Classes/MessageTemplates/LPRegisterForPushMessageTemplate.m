//
//  LPRegisterForPushMessageTemplate.m
//  LeanplumSDK-iOS
//
//  Created by Mayank Sanganeria on 2/7/20.
//  Copyright © 2020 Leanplum. All rights reserved.
//

#import "LPRegisterForPushMessageTemplate.h"
#import "LPPushMessageTemplate.h"

@implementation LPRegisterForPushMessageTemplate

+(void)defineAction
{
    [Leanplum defineAction:LPMT_REGISTER_FOR_PUSH
                    ofKind:kLeanplumActionKindAction
             withArguments:@[]
             withResponder:^BOOL(LPActionContext *context) {

        LPRegisterForPushMessageTemplate *template = [[LPRegisterForPushMessageTemplate alloc] init];
        
        if ([template shouldShowPushMessage]) {
            // Try showing the native prompt
            // iOS can prevent showing the dialog if recently asked
            [template showNativePushPrompt];
            // Will count View event
            return YES;
        } else {
            return NO;
        }
        
        return YES;
    }];
}

/**
 * If push notifications are not enabled returns true.
 * Does not perform other checks as Push Ask to Ask to enable re-triggering of native prompt
 */
-(BOOL)shouldShowPushMessage
{
    if ([self isPushEnabled]) {
        NSLog(@"Leanplum: Pushes already enabled");
        return NO;
    } else {
        return YES;
    }
}

@end
