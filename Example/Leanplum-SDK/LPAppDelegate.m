//
//  LPAppDelegate.m
//  Leanplum-SDK
//
//  Created by Ben Marten on 08/29/2016.
//  Copyright (c) 2016 Ben Marten. All rights reserved.
//

#import "LPAppDelegate.h"
#if LP_NOT_TV & __IPHONE_OS_VERSION_MIN_REQUIRED >= 100000
#import <UserNotifications/UserNotifications.h>
#endif

@implementation LPAppDelegate

- (BOOL)application:(UIApplication *)application
        didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    [[UIApplication sharedApplication] registerForRemoteNotifications];
#if LP_NOT_TV & __IPHONE_OS_VERSION_MIN_REQUIRED >= 100000
        [[UNUserNotificationCenter currentNotificationCenter] setDelegate:self];
        [[UNUserNotificationCenter currentNotificationCenter] requestAuthorizationWithOptions:
         UNAuthorizationOptionAlert|UNAuthorizationOptionBadge|UNAuthorizationOptionSound
                        completionHandler:^(BOOL granted, NSError * _Nullable error) {
                            NSLog(@"Granted? %@", granted ? @"YES" : @"NO");
                            NSLog(@"Error: %@", error);
                        }];
#endif
    return YES;
}

#if LP_NOT_TV
- (void)userNotificationCenter:(UNUserNotificationCenter *)center
       willPresentNotification:(UNNotification *)notification
         withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler
{
    NSLog(@"Will present notification: %@", notification);
    completionHandler(UNNotificationPresentationOptionAlert|
                      UNNotificationPresentationOptionBadge|
                      UNNotificationPresentationOptionSound);
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center
didReceiveNotificationResponse:(UNNotificationResponse *)response
         withCompletionHandler:(void (^)())completionHandler
{
    NSLog(@"didReceiveNotificationResponse: %@", response);
    completionHandler();
}
#endif

@end
