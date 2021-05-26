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

@implementation NSObject (LeanplumExtension)

- (void)leanplum_application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    LPLog(LPDebug, @"Called swizzled didRegisterForRemoteNotificationsWithDeviceToken");
    [[LPPushNotificationsManager sharedManager].handler didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];

    // Call overridden method.
    if ([[LPPushNotificationsManager sharedManager] swizzledApplicationDidRegisterRemoteNotifications] && [self respondsToSelector:@selector(leanplum_application:didRegisterForRemoteNotificationsWithDeviceToken:)]) {
        [self performSelector:@selector(leanplum_application:didRegisterForRemoteNotificationsWithDeviceToken:)
                   withObject:application withObject:deviceToken];
    }
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
#pragma clang diagnostic ignored "-Wstrict-prototypes"
- (void)leanplum_application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings
{
    LPLog(LPDebug, @"Called swizzled didRegisterUserNotificationSettings:notificationSettings");
    [[LPPushNotificationsManager sharedManager].handler didRegisterUserNotificationSettings:notificationSettings];

    // Call overridden method.
    if ([[LPPushNotificationsManager sharedManager] swizzledApplicationDidRegisterUserNotificationSettings] &&
        [self respondsToSelector:@selector(leanplum_application:didRegisterUserNotificationSettings:)]) {
        [self performSelector:@selector(leanplum_application:didRegisterUserNotificationSettings:)
                   withObject:application withObject:notificationSettings];
    }
}

- (void)leanplum_application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    LPLog(LPDebug, @"Called swizzled didFailToRegisterForRemoteNotificationsWithError: %@", error);
    [[LPPushNotificationsManager sharedManager].handler didFailToRegisterForRemoteNotificationsWithError:error];

    // Call overridden method.
    if ([[LPPushNotificationsManager sharedManager] swizzledApplicationDidFailToRegisterForRemoteNotificationsWithError] &&
        [self respondsToSelector:@selector(leanplum_application:didFailToRegisterForRemoteNotificationsWithError:)]) {
        [self performSelector:@selector(leanplum_application:didFailToRegisterForRemoteNotificationsWithError:)
                   withObject:application withObject:error];
    }
}

- (void)leanplum_application:(UIApplication *)application
didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    LP_TRY
    LPLog(LPDebug, @"Called swizzled didReceiveRemoteNotification");
    [[LPPushNotificationsManager sharedManager].handler didReceiveRemoteNotification:userInfo
                                    withAction:nil
                        fetchCompletionHandler:nil];
    LP_END_TRY

    // Call overridden method.
    if ([[LPPushNotificationsManager sharedManager] swizzledApplicationDidReceiveRemoteNotification] && [self respondsToSelector:@selector(leanplum_application:didReceiveRemoteNotification:)]) {
        [self performSelector:@selector(leanplum_application:didReceiveRemoteNotification:)
                   withObject:application withObject:userInfo];
    }
}

- (void)leanplum_application:(UIApplication *)application
didReceiveRemoteNotification:(NSDictionary *)userInfo
      fetchCompletionHandler:(LeanplumFetchCompletionBlock)completionHandler
{
    LPLog(LPDebug, @"Called swizzled didReceiveRemoteNotification:fetchCompletionHandler");
    
    LPInternalState *state = [LPInternalState sharedState];
    state.calledHandleNotification = NO;
    LeanplumFetchCompletionBlock leanplumCompletionHandler;

    // Call overridden method.
    if ([[LPPushNotificationsManager sharedManager] swizzledApplicationDidReceiveRemoteNotificationWithCompletionHandler] && [self respondsToSelector:@selector(leanplum_application:didReceiveRemoteNotification:fetchCompletionHandler:)]) {
        leanplumCompletionHandler = nil;
        [self leanplum_application:application didReceiveRemoteNotification:userInfo fetchCompletionHandler:completionHandler];
    } else {
        leanplumCompletionHandler = completionHandler;
    }

    // Prevents handling the notification twice if the original method calls handleNotification
    // explicitly.
    if (!state.calledHandleNotification) {
        LP_TRY
        [[LPPushNotificationsManager sharedManager].handler didReceiveRemoteNotification:userInfo
                                                           withAction:nil
                                               fetchCompletionHandler:leanplumCompletionHandler];
        LP_END_TRY
    }
    state.calledHandleNotification = NO;
}

- (void)leanplum_userNotificationCenter:(UNUserNotificationCenter *)center
         didReceiveNotificationResponse:(UNNotificationResponse *)response
                  withCompletionHandler:(void (^)())completionHandler
API_AVAILABLE(ios(10.0))
{

    LPLog(LPDebug, @"Called swizzled didReceiveNotificationResponse:withCompletionHandler");

    // Call overridden method.
    SEL selector = @selector(leanplum_userNotificationCenter:didReceiveNotificationResponse:
                             withCompletionHandler:);

        if ([[LPPushNotificationsManager sharedManager] swizzledUserNotificationCenterDidReceiveNotificationResponseWithCompletionHandler] &&
        [self respondsToSelector:selector]) {
        [self leanplum_userNotificationCenter:center
               didReceiveNotificationResponse:response
                        withCompletionHandler:completionHandler];
    }
    [[LPPushNotificationsManager sharedManager].handler didReceiveNotificationResponse:response withCompletionHandler:completionHandler];
}

-(void)leanplum_userNotificationCenter:(UNUserNotificationCenter *)center
               willPresentNotification:(UNNotification *)notification
                 withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler
API_AVAILABLE(ios(10.0))
{
    LPLog(LPDebug, @"Called swizzled willPresentNotification:withCompletionHandler");

    // Call overridden method.
    SEL selector = @selector(leanplum_userNotificationCenter:willPresentNotification:withCompletionHandler:);

    if ([[LPPushNotificationsManager sharedManager] swizzledUserNotificationCenterWillPresentNotificationWithCompletionHandler] &&
        [self respondsToSelector:selector]) {
        [self leanplum_userNotificationCenter:center
                      willPresentNotification:notification
                        withCompletionHandler:completionHandler];
    }

    [[LPPushNotificationsManager sharedManager].handler willPresentNotification:notification withCompletionHandler:completionHandler];
}

- (void)leanplum_application:(UIApplication *)application
 didReceiveLocalNotification:(UILocalNotification *)localNotification
{
    LP_TRY
    [[LPLocalNotificationsManager sharedManager].handler didReceiveLocalNotification:localNotification];
    LP_END_TRY

    if ([[LPPushNotificationsManager sharedManager] swizzledApplicationDidReceiveLocalNotification] &&
        [self respondsToSelector:@selector(leanplum_application:didReceiveLocalNotification:)]) {
        [self performSelector:@selector(leanplum_application:didReceiveLocalNotification:)
                   withObject:application withObject:localNotification];
    }
}

#pragma clang diagnostic pop

@end


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
        _swizzledApplicationDidRegisterRemoteNotifications = NO;
        _swizzledApplicationDidRegisterUserNotificationSettings = NO;
        _swizzledApplicationDidFailToRegisterForRemoteNotificationsWithError = NO;
        _swizzledApplicationDidReceiveRemoteNotification = NO;
        _swizzledApplicationDidReceiveRemoteNotificationWithCompletionHandler = NO;
        _swizzledApplicationDidReceiveLocalNotification = NO;
        _swizzledUserNotificationCenterDidReceiveNotificationResponseWithCompletionHandler = NO;
        _swizzledUserNotificationCenterWillPresentNotificationWithCompletionHandler = NO;
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
        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        [notificationCenter addObserver:self
                               selector:@selector(handleApplicationDidBecomeActive:)
                                   name:UIApplicationDidFinishLaunchingNotification
                                 object:nil];
    });
}

+ (void)handleApplicationDidBecomeActive:(NSNotification *)notification {
    [[LPPushNotificationsManager sharedManager] swizzleAppMethods];
    NSDictionary *userInfo = notification.userInfo[UIApplicationLaunchOptionsRemoteNotificationKey];
    if (userInfo != nil) {
        if (@available(iOS 10, *)) {
            if ([UNUserNotificationCenter currentNotificationCenter].delegate != nil) {
                [[LPPushNotificationsManager sharedManager].handler handleWillPresentNotification:userInfo];
                return;
            }
        }
        [[LPPushNotificationsManager sharedManager].handler didReceiveRemoteNotification:userInfo];
    }
}

- (void)swizzleAppMethods
{
    BOOL swizzlingEnabled = [LPUtils isSwizzlingEnabled];
    if (!swizzlingEnabled)
    {
        LPLog(LPDebug, @"Method swizzling is disabled.");
    }
    
    id appDelegate = [[UIApplication sharedApplication] delegate];
    if (appDelegate && [NSStringFromClass([appDelegate class])
                        rangeOfString:@"AppDelegateProxy"].location != NSNotFound) {
        @try {
            SEL selector = NSSelectorFromString(@"originalAppDelegate");
            IMP imp = [appDelegate methodForSelector:selector];
            id (*func)(id, SEL) = (void *)imp;
            id originalAppDelegate = func(appDelegate, selector);
            if (originalAppDelegate) {
                appDelegate = originalAppDelegate;
            }
        }
        @catch (NSException *exception) {
            // Ignore. Means that app delegate doesn't repsond to the selector.
            // Can't use respondsToSelector since proxies override this method so that
            // it doesn't work for this particular selector.
        }
    }
    
    if (swizzlingEnabled)
    {
        // Detect when registered for push notifications.
        self.swizzledApplicationDidRegisterRemoteNotifications =
        [LPSwizzle hookInto:@selector(application:didRegisterForRemoteNotificationsWithDeviceToken:)
               withSelector:@selector(leanplum_application:didRegisterForRemoteNotificationsWithDeviceToken:)
                  forObject:[appDelegate class]];
        
        // Detect when registered for user notification types.
        self.swizzledApplicationDidRegisterUserNotificationSettings =
        [LPSwizzle hookInto:@selector(application:didRegisterUserNotificationSettings:)
               withSelector:@selector(leanplum_application:didRegisterUserNotificationSettings:)
                  forObject:[appDelegate class]];
        
        // Detect when couldn't register for push notifications.
        self.swizzledApplicationDidFailToRegisterForRemoteNotificationsWithError =
        [LPSwizzle hookInto:@selector(application:didFailToRegisterForRemoteNotificationsWithError:)
               withSelector:@selector(leanplum_application:didFailToRegisterForRemoteNotificationsWithError:)
                  forObject:[appDelegate class]];
        
        // Detect push while app is running.
        SEL applicationDidReceiveRemoteNotificationSelector = @selector(application:didReceiveRemoteNotification:);
        Method applicationDidReceiveRemoteNotificationMethod = class_getInstanceMethod(
                                                                                       [appDelegate class],
                                                                                       applicationDidReceiveRemoteNotificationSelector);
        
        __weak __typeof__(self) weakSelf = self;
        void (^swizzleApplicationDidReceiveRemoteNotification)(void) = ^{
            weakSelf.swizzledApplicationDidReceiveRemoteNotification =
            [LPSwizzle hookInto:applicationDidReceiveRemoteNotificationSelector
                   withSelector:@selector(leanplum_application:
                                          didReceiveRemoteNotification:)
                      forObject:[appDelegate class]];
        };
        
        SEL applicationDidReceiveRemoteNotificationFetchCompletionHandlerSelector =
        @selector(application:didReceiveRemoteNotification:fetchCompletionHandler:);
        Method applicationDidReceiveRemoteNotificationCompletionHandlerMethod = class_getInstanceMethod(
                                                                                                        [appDelegate class],
                                                                                                        applicationDidReceiveRemoteNotificationFetchCompletionHandlerSelector);
        void (^swizzleApplicationDidReceiveRemoteNotificationFetchCompletionHandler)(void) = ^{
            weakSelf.swizzledApplicationDidReceiveRemoteNotificationWithCompletionHandler =
            [LPSwizzle hookInto:applicationDidReceiveRemoteNotificationFetchCompletionHandlerSelector
                   withSelector:@selector(leanplum_application:
                                          didReceiveRemoteNotification:
                                          fetchCompletionHandler:)
                      forObject:[appDelegate class]];
        };
        
        SEL userNotificationCenterDidReceiveNotificationResponseWithCompletionHandlerSelector =
        @selector(userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:);
        Method userNotificationCenterDidReceiveNotificationResponseWithCompletionHandlerMethod =
        class_getInstanceMethod([appDelegate class],
                                userNotificationCenterDidReceiveNotificationResponseWithCompletionHandlerSelector);
        void (^swizzleUserNotificationDidReceiveNotificationResponseWithCompletionHandler)(void) = ^{
            weakSelf.swizzledUserNotificationCenterDidReceiveNotificationResponseWithCompletionHandler =
            [LPSwizzle hookInto:userNotificationCenterDidReceiveNotificationResponseWithCompletionHandlerSelector
                   withSelector:@selector(leanplum_userNotificationCenter:
                                          didReceiveNotificationResponse:
                                          withCompletionHandler:)
                      forObject:[appDelegate class]];
        };

        SEL userNotificationCenterWillPresentNotificationWithCompletionHandlerSelector = @selector(userNotificationCenter:
                                                                                                   willPresentNotification:
                                                                                                   withCompletionHandler:);
        Method userNotificationCenterWillPresentNotificationWithCompletionHandlerMethod = class_getInstanceMethod([appDelegate class],
                                                                                                                  userNotificationCenterWillPresentNotificationWithCompletionHandlerSelector);
        void (^swizzleUserNotificationWillPresentNotificationWithCompletionHandler)(void) = ^{
            weakSelf.swizzledUserNotificationCenterWillPresentNotificationWithCompletionHandler = [LPSwizzle
                                                                                          hookInto:userNotificationCenterWillPresentNotificationWithCompletionHandlerSelector
                                                                                          withSelector:@selector(leanplum_userNotificationCenter:willPresentNotification:withCompletionHandler:)
                                                                                          forObject:[appDelegate class]];
        };
        
        if (!applicationDidReceiveRemoteNotificationMethod
            && !applicationDidReceiveRemoteNotificationCompletionHandlerMethod) {
            swizzleApplicationDidReceiveRemoteNotification();
            swizzleApplicationDidReceiveRemoteNotificationFetchCompletionHandler();
            if (NSClassFromString(@"UNUserNotificationCenter")) {
                swizzleUserNotificationDidReceiveNotificationResponseWithCompletionHandler();
                swizzleUserNotificationWillPresentNotificationWithCompletionHandler();
            }
        } else {
            if (applicationDidReceiveRemoteNotificationMethod) {
                swizzleApplicationDidReceiveRemoteNotification();
            }
            if (applicationDidReceiveRemoteNotificationCompletionHandlerMethod) {
                swizzleApplicationDidReceiveRemoteNotificationFetchCompletionHandler();
            }
            if (NSClassFromString(@"UNUserNotificationCenter")) {
                if (userNotificationCenterDidReceiveNotificationResponseWithCompletionHandlerMethod) {
                    swizzleUserNotificationDidReceiveNotificationResponseWithCompletionHandler();
                }
                if (userNotificationCenterWillPresentNotificationWithCompletionHandlerMethod) {
                    swizzleUserNotificationWillPresentNotificationWithCompletionHandler();
                }
            }
        }
        
        // Detect local notifications while app is running.
        self.swizzledApplicationDidReceiveLocalNotification =
        [LPSwizzle hookInto:@selector(application:didReceiveLocalNotification:)
               withSelector:@selector(leanplum_application:didReceiveLocalNotification:)
                  forObject:[appDelegate class]];
    }
    else
    {
        LPLog(LPInfo, @"Method swizzling is disabled, make sure to manually call Leanplum methods.");
    }
}

// Block to run to decide whether to show the notification
// when it is received while the app is running.
- (void)setShouldHandleNotification:(LeanplumShouldHandleNotificationBlock)block
{
    self.handler.shouldHandleNotification = block;
}

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
