//
//  LPLocalNotificationsManager.m
//  Leanplum-iOS-Location
//
//  Created by Dejan Krstevski on 12.05.20.
//  Copyright © 2020 Leanplum. All rights reserved.
//

#import "LPLocalNotificationsManager.h"
#import "LeanplumInternal.h"
#import "LPNotificationsConstants.h"
#import "LPNotificationsManager.h"

@implementation LPLocalNotificationsManager

+ (LPLocalNotificationsManager *)sharedManager
{
    static LPLocalNotificationsManager *_sharedManager = nil;
    static dispatch_once_t localNotificationsManagerToken;
    dispatch_once(&localNotificationsManagerToken, ^{
        _sharedManager = [[self alloc] init];
    });
    return _sharedManager;
}

- (instancetype)init
{
    if(self = [super init])
    {
        _handler = [[LPLocalNotificationsHandler alloc] init];
    }
    return self;
}

- (void)listenForLocalNotifications
{
    [Leanplum onAction:LP_PUSH_NOTIFICATION_ACTION invoke:^BOOL(LPActionContext *context) {
        LP_END_USER_CODE
        UIApplication *app = [UIApplication sharedApplication];

        BOOL contentAvailable = [context boolNamed:@"iOS options.Preload content"];
        NSString *message = [context stringNamed:@"Message"];

        // Don't send notification if the user doesn't have the permission enabled.
        if ([app respondsToSelector:@selector(currentUserNotificationSettings)]) {
            BOOL isSilentNotification = message.length == 0 && contentAvailable;
            if (!isSilentNotification) {
                UIUserNotificationSettings *currentSettings = [app currentUserNotificationSettings];
                if ([currentSettings types] == UIUserNotificationTypeNone) {
                    return NO;
                }
            }
        }

        NSString *messageId = context.messageId;

        NSDictionary *messageConfig = [LPVarCache sharedCache].messageDiffs[messageId];
        
        NSNumber *countdown = messageConfig[@"countdown"];
        if (context.isPreview) {
            countdown = @(5.0);
        }
        if (![countdown.class isSubclassOfClass:NSNumber.class]) {
            LPLog(LPDebug, @"Invalid notification countdown: %@", countdown);
            return NO;
        }
        int countdownSeconds = [countdown intValue];
        NSDate *eta = [[NSDate date] dateByAddingTimeInterval:countdownSeconds];

        // If there's already one scheduled before the eta, discard this.
        // Otherwise, discard the scheduled one.
        NSArray *notifications = [app scheduledLocalNotifications];
        for (UILocalNotification *notification in notifications) {
            NSString *messageId = [[LPNotificationsManager shared] messageIdFromUserInfo:[notification userInfo]];
            if ([messageId isEqualToString:context.messageId]) {
                NSComparisonResult comparison = [notification.fireDate compare:eta];
                if (comparison == NSOrderedAscending) {
                    return NO;
                } else {
                    [app cancelLocalNotification:notification];
                }
            }
        }

        UILocalNotification *localNotif = [[UILocalNotification alloc] init];
        localNotif.fireDate = eta;
        localNotif.timeZone = [NSTimeZone defaultTimeZone];
        if (message) {
            localNotif.alertBody = message;
        } else {
            localNotif.alertBody = LP_VALUE_DEFAULT_PUSH_MESSAGE;
        }
        localNotif.alertAction = @"View";

        if ([localNotif respondsToSelector:@selector(setCategory:)]) {
            NSString *category = [context stringNamed:@"iOS options.Category"];
            if (category) {
                localNotif.category = category;
            }
        }

        NSString *sound = [context stringNamed:@"iOS options.Sound"];
        if (sound) {
            localNotif.soundName = sound;
        } else {
            localNotif.soundName = UILocalNotificationDefaultSoundName;
        }

        NSString *badge = [context stringNamed:@"iOS options.Badge"];
        if (badge) {
            localNotif.applicationIconBadgeNumber = [badge intValue];
        }

        NSDictionary *userInfo = [context dictionaryNamed:@"Advanced options.Data"];
        NSString *openAction = [context stringNamed:LP_VALUE_DEFAULT_PUSH_ACTION];
        BOOL muteInsideApp = [context boolNamed:@"Advanced options.Mute inside app"];

        // Specify custom data for the notification
        NSMutableDictionary *mutableInfo;
        if (userInfo) {
            mutableInfo = [userInfo mutableCopy];
        } else {
            mutableInfo = [NSMutableDictionary dictionary];
        }
        
        // Adding body message manually.
        mutableInfo[@"aps"] = @{@"alert":@{@"body": message ?: @""} };

        // Specify open action
        if (openAction) {
            if (muteInsideApp) {
                mutableInfo[LP_KEY_PUSH_MUTE_IN_APP] = messageId;
            } else {
                mutableInfo[LP_KEY_PUSH_MESSAGE_ID] = messageId;
            }
        } else {
            if (muteInsideApp) {
                mutableInfo[LP_KEY_PUSH_NO_ACTION_MUTE] = messageId;
            } else {
                mutableInfo[LP_KEY_PUSH_NO_ACTION] = messageId;
            }
        }

        localNotif.userInfo = mutableInfo;

        // Schedule the notification
        [app scheduleLocalNotification:localNotif];
        
        if ([LPConstantsState sharedState].isDevelopmentModeEnabled) {
            LPLog(LPInfo, @"Scheduled notification");
        }
        LP_BEGIN_USER_CODE
        return YES;
    }];

    [Leanplum onAction:@"__Cancel__Push Notification" invoke:^BOOL(LPActionContext *context) {
        LP_END_USER_CODE
        UIApplication *app = [UIApplication sharedApplication];
        NSArray *notifications = [app scheduledLocalNotifications];
        BOOL didCancel = NO;
        for (UILocalNotification *notification in notifications) {
            NSString *messageId = [[LPNotificationsManager shared] messageIdFromUserInfo:[notification userInfo]];
            if ([messageId isEqualToString:context.messageId]) {
                [app cancelLocalNotification:notification];
                if ([LPConstantsState sharedState].isDevelopmentModeEnabled) {
                    LPLog(LPInfo, @"Cancelled notification");
                }
                didCancel = YES;
            }
        }
        LP_BEGIN_USER_CODE
        return didCancel;
    }];
}

@end
