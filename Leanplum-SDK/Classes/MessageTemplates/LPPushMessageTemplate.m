//
//  LPPushMessageTemplate.m
//  Leanplum-iOS-SDK
//
//  Created by Nikola Zagorchev on 19.08.20.
//

#import "LPPushMessageTemplate.h"
#import "LPActionManager.h"
#import "LPLogManager.h"

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
    [[LPPushNotificationsManager sharedManager] enableSystemPush];
}

- (BOOL)isPushEnabled
{
    return [[LPPushNotificationsManager sharedManager] isPushEnabled];
}

- (BOOL)hasDisabledAskToAsk
{
    return [[LPPushNotificationsManager sharedManager] hasDisabledAskToAsk];
}

@end
