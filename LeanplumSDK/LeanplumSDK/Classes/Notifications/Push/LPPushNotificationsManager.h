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

+ (LPPushNotificationsManager *)sharedManager;
- (void)enableSystemPush;
- (BOOL)isPushEnabled;
- (void)refreshPushPermissions;
- (void)disableAskToAsk;
- (BOOL)hasDisabledAskToAsk;
- (NSString *)leanplum_createUserNotificationSettingsKey;
- (NSString *)pushToken;
- (void)updatePushToken:(NSString *)newToken;
- (void)removePushToken;

@end

NS_ASSUME_NONNULL_END
