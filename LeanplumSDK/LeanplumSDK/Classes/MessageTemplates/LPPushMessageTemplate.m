//
//  LPPushMessageTemplate.m
//  Leanplum-iOS-SDK
//
//  Created by Nikola Zagorchev on 19.08.20.
//

#import "LPPushMessageTemplate.h"
#import "LPActionTriggerManager.h"
#import "LPLogManager.h"
#import "LeanplumInternal.h"
#import <Leanplum/Leanplum-Swift.h>

@implementation LPPushMessageTemplate

-(BOOL)shouldShowPushMessage
{
    if ([self isPushEnabled]) {
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
    [[Leanplum notificationsManager] enableSystemPush];
}

- (BOOL)isPushEnabled
{
    return [[Leanplum notificationsManager] isPushEnabled];
}

- (BOOL)hasDisabledAskToAsk
{
    return [Leanplum notificationsManager].isAskToAskDisabled;
}

@end
