//
//  LPPushMessageTemplate.m
//  Leanplum-iOS-SDK
//
//  Created by Nikola Zagorchev on 19.08.20.
//

#import "LPPushMessageTemplate.h"
#import "LPActionManager.h"
#import "LPLogManager.h"
#import <Leanplum/Leanplum-Swift.h>

@implementation LPPushMessageTemplate

-(BOOL)shouldShowPushMessage
{
    if ([Leanplum isPreLeanplumInstall]) {
        LPLog(LPDebug, @"'Ask to ask' conservatively falls back to just 'ask' for pre-Leanplum installs");
        [self showNativePushPrompt];
        return NO;
    } else if ([self isPushEnabled]) {
        LPLog(LPDebug, @"Pushes already enabled");
        return NO;
    } else if ([self hasDisabledAskToAsk]) {
        LPLog(LPDebug, @" Already asked to push");
        return NO;
    } else {
        return YES;
    }
}

-(void)showNativePushPrompt
{
    [LeanplumPushNotificationUtils enableSystemPush];
}

- (BOOL)isPushEnabled
{
    return [LeanplumPushNotificationUtils isPushEnabled];
}

- (BOOL)hasDisabledAskToAsk
{
    return [LeanplumPushNotificationUtils hasDisabledAskToAsk];
}

@end
