//
//  LPPushNotificationsManager.h
//  Leanplum-iOS-Location
//
//  Created by Dejan Krstevski on 5.05.20.
//  Copyright © 2020 Leanplum. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LPPushNotificationsHandler.h"

NS_ASSUME_NONNULL_BEGIN

@interface LPPushNotificationsManager : NSObject
@property (nonatomic, strong) LPPushNotificationsHandler *handler;

@property (nonatomic, assign) BOOL swizzledApplicationDidRegisterRemoteNotifications;
@property (nonatomic, assign) BOOL swizzledApplicationDidRegisterUserNotificationSettings;
@property (nonatomic, assign) BOOL swizzledApplicationDidFailToRegisterForRemoteNotificationsWithError;
@property (nonatomic, assign) BOOL swizzledApplicationDidReceiveRemoteNotification;
@property (nonatomic, assign) BOOL swizzledApplicationDidReceiveRemoteNotificationWithCompletionHandler;
@property (nonatomic, assign) BOOL swizzledApplicationDidReceiveLocalNotification;
@property (nonatomic, assign) BOOL swizzledUserNotificationCenterDidReceiveNotificationResponseWithCompletionHandler;
@property (nonatomic, assign) BOOL swizzledUserNotificationCenterWillPresentNotificationWithCompletionHandler;


+ (LPPushNotificationsManager *)sharedManager;
- (void)enableSystemPush;
- (BOOL)isPushEnabled;
- (void)refreshPushPermissions;
- (void)disableAskToAsk;
- (BOOL)hasDisabledAskToAsk;
- (void)setShouldHandleNotification:(LeanplumShouldHandleNotificationBlock)block;
- (NSString *)leanplum_createUserNotificationSettingsKey;
- (NSString *)pushToken;
- (void)updatePushToken:(NSString *)newToken;
- (void)removePushToken;

@end

NS_ASSUME_NONNULL_END
