//
//  LPPushNotificationsManager.m
//  Leanplum-iOS-Location
//
//  Created by Dejan Krstevski on 5.05.20.
//  Copyright © 2020 Leanplum. All rights reserved.
//

#import "LPPushNotificationsManager.h"
#import "LeanplumInternal.h"
#import "LPAPIConfig.h"
#import <objc/runtime.h>
#import <Leanplum/Leanplum-Swift.h>

@implementation LPPushNotificationsManager

+ (LPPushNotificationsManager *)sharedManager
{
    static LPPushNotificationsManager *_sharedManager = nil;
    static dispatch_once_t pushNotificationsManagerToken;
    dispatch_once(&pushNotificationsManagerToken, ^{
        _sharedManager = [[self alloc] init];
    });
    return _sharedManager;
}

- (instancetype)init
{
    if (self = [super init]) {
        _handler = [[LPPushNotificationsHandler alloc] init];
    }
    return self;
}

#pragma mark Enable Push
-(void)enableSystemPush
{
    // The commented lines below are an alternative for iOS 8 that will deep link to the app in
    // device Settings.
    //    NSURL *appSettings = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
    //    [[UIApplication sharedApplication] openURL:appSettings];

    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:DEFAULTS_LEANPLUM_ENABLED_PUSH];
    [Leanplum synchronizeDefaults];
    // When system asks user for push notification we should also disable our dialog, because
    // if users accept/declines we don't want to show dialog anymore since system will block default one.
    [self disableAskToAsk];

    LeanplumPushSetupBlock block = [Leanplum pushSetupBlock];
    if (block) {
        // If the app used [Leanplum setPushSetup:...], call the block.
        block();
        return;
    }
    
    // iOS 10.0, tvOS 10.0, macOS 10.14
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 100000 || __TV_OS_VERSION_MAX_ALLOWED >= 100000 || __MAC_OS_X_VERSION_MAX_ALLOWED >= 101400
        if (@available(iOS 10, tvOS 10, macOS 10.14, *))
        {
            UNUserNotificationCenter *notificationCenter = [UNUserNotificationCenter currentNotificationCenter];
            UNAuthorizationOptions options = UNAuthorizationOptionAlert | UNAuthorizationOptionBadge | UNAuthorizationOptionSound;
            [notificationCenter requestAuthorizationWithOptions:options completionHandler:^(BOOL granted, NSError * _Nullable error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (granted) {
                        [[UIApplication sharedApplication] registerForRemoteNotifications];
                    } else {
                        LPLog(LPError, @"Failed to request authorization for user notifications: %@", error ? error : @"nil");
                    }
                });
            }];
            
            return;
        }
#endif
        
        // iOS 8.0
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
        if (@available(iOS 8.0, *))
        {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
            UIUserNotificationType notificationTypes = UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound;
            UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:notificationTypes categories:nil];
            [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
            [[UIApplication sharedApplication] registerForRemoteNotifications];
#pragma clang diagnostic pop
            return;
        }
#endif
        
        // iOS 3.0
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 30000
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        UIRemoteNotificationType remoteNotificationTypes = UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound;
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:remoteNotificationTypes];
#pragma clang diagnostic pop
#endif
}

- (BOOL)isPushEnabled
{
    // Run on main thread.
    if (![NSThread isMainThread]) {
        BOOL __block output = NO;
        dispatch_sync(dispatch_get_main_queue(), ^{
            output = [self isPushEnabled];
        });
        return output;
    }

    UIApplication *application = [UIApplication sharedApplication];
    BOOL enabled;

    // Try to use the newer isRegisteredForRemoteNotifications otherwise use the enabledRemoteNotificationTypes.
    if ([application respondsToSelector:@selector(isRegisteredForRemoteNotifications)]) {
        enabled = [application isRegisteredForRemoteNotifications];
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        UIRemoteNotificationType types = [application enabledRemoteNotificationTypes];
        enabled = types & UIRemoteNotificationTypeAlert;
#pragma clang diagnostic pop
    }
    return enabled;
}

// If notification were enabled by Leanplum's "Push Ask to Ask" or "Register For Push",
// refreshPushPermissions will do the same registration for subsequent app sessions.
// refreshPushPermissions is called by [Leanplum start].
- (void)refreshPushPermissions
{
    if ([[NSUserDefaults standardUserDefaults] boolForKey:DEFAULTS_LEANPLUM_ENABLED_PUSH]) {
        [self enableSystemPush];
    }
}

- (void)disableAskToAsk
{
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:DEFAULTS_ASKED_TO_PUSH];
    [Leanplum synchronizeDefaults];
}

- (BOOL)hasDisabledAskToAsk
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:DEFAULTS_ASKED_TO_PUSH];
}

- (NSString *)leanplum_createUserNotificationSettingsKey
{
    return [NSString stringWithFormat:
            LEANPLUM_DEFAULTS_USER_NOTIFICATION_SETTINGS_KEY,
            [LPAPIConfig sharedConfig].appId, [LPAPIConfig sharedConfig].userId, [LPAPIConfig sharedConfig].deviceId];
}

- (NSString *)pushToken
{
    return [[NSUserDefaults standardUserDefaults] stringForKey:[self pushTokenKey]];
}

- (NSString *)pushTokenKey
{
    return [NSString stringWithFormat: LEANPLUM_DEFAULTS_PUSH_TOKEN_KEY,
            [LPAPIConfig sharedConfig].appId, [LPAPIConfig sharedConfig].userId, [LPAPIConfig sharedConfig].deviceId];
}

- (void)updatePushToken:(NSString *)newToken
{
    [[NSUserDefaults standardUserDefaults] setObject:newToken forKey:[self pushTokenKey]];
    [Leanplum synchronizeDefaults];
}

- (void)removePushToken
{
    NSString *tokenKey = [self pushTokenKey];
    if ([[NSUserDefaults standardUserDefaults] stringForKey:tokenKey]) {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:tokenKey];
        [Leanplum synchronizeDefaults];
    }
}

#pragma mark Swizzle Methods

+ (void) load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if ([LPUtils isSwizzlingEnabled]) {
            [[Leanplum notificationsManager].proxy addDidFinishLaunchingObserver];
        }
    });
}

// Block to run to decide whether to show the notification
// when it is received while the app is running.
- (void)setShouldHandleNotification:(LeanplumShouldHandleNotificationBlock)block
{
    self.handler.shouldHandleNotification = block;
}

- (void) dealloc {
    [[Leanplum notificationsManager].proxy removeDidFinishLaunchingObserver];
}

@end
