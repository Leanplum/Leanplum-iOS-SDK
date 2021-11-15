//
//  LPPushNotificationsHandler.h
//  Leanplum-iOS-Location
//
//  Created by Dejan Krstevski on 5.05.20.
//  Copyright © 2020 Leanplum. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Leanplum.h"

NS_ASSUME_NONNULL_BEGIN

@interface LPPushNotificationsHandler : NSObject

@property (nonatomic, readonly) NSDictionary *currentUserNotificationSettings;

- (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)token;
- (void)didFailToRegisterForRemoteNotificationsWithError:(NSError *)error;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
#pragma clang diagnostic ignored "-Wstrict-prototypes"
- (void)didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings;
- (BOOL)updateUserNotificationSettings:(NSDictionary *)newSettings;
- (void)sendUserNotificationSettingsIfChanged:(UIUserNotificationSettings *)notificationSettings;
#pragma clang diagnostic pop

@end

NS_ASSUME_NONNULL_END
