//
//  LPPushNotificationsManager.m
//  Leanplum-iOS-Location
//
//  Created by Dejan . Krstevski on 5.05.20.
//

#import "LPPushNotificationsManager.h"
#import "LeanplumInternal.h"
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

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wstrict-prototypes"
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

#pragma clang diagnostic pop

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

    // When system asks user for push notification we should also disable our dialog, because
    // if users accept/declines we don't want to show dialog anymore since system will block default one.
    [self disableAskToAsk];

    LeanplumPushSetupBlock block = [Leanplum pushSetupBlock];
    if (block) {
        // If the app used [Leanplum setPushSetup:...], call the block.
        block();
        return;
    }
    // Otherwise use boilerplate code from docs.
    id notificationCenterClass = NSClassFromString(@"UNUserNotificationCenter");
    if (notificationCenterClass) {
        // iOS 10.
        SEL selector = NSSelectorFromString(@"currentNotificationCenter");
        id notificationCenter =
        ((id (*)(id, SEL)) [notificationCenterClass methodForSelector:selector])
        (notificationCenterClass, selector);
        if (notificationCenter) {
            selector = NSSelectorFromString(@"requestAuthorizationWithOptions:completionHandler:");
            IMP method = [notificationCenter methodForSelector:selector];
            void (*func)(id, SEL, unsigned long long, void (^)(BOOL, NSError *__nullable)) =
            (void *) method;
            func(notificationCenter, selector,
                 0b111, /* badges, sounds, alerts */
                 ^(BOOL granted, NSError *__nullable error) {
                     if (error) {
                         NSLog(@"Leanplum: Failed to request authorization for user "
                               "notifications: %@", error);
                     }
                 });
        }
        [[UIApplication sharedApplication] registerForRemoteNotifications];
    } else if ([[UIApplication sharedApplication] respondsToSelector:
                @selector(registerUserNotificationSettings:)]) {
            // iOS 8-9.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
            UIUserNotificationSettings *settings = [UIUserNotificationSettings
                                                    settingsForTypes:UIUserNotificationTypeAlert |
                                                    UIUserNotificationTypeBadge |
                                                    UIUserNotificationTypeSound categories:nil];
            [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
            [[UIApplication sharedApplication] registerForRemoteNotifications];
#pragma clang diagnostic pop
    }
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

#pragma mark Swizzle Methods

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
        
        __typeof__(self) weakSelf = self;
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
        LPLog(LPWarning, @"Method swizzling is disabled, make sure to manually call Leanplum methods.");
    }
    
    // Detect receiving notifications.
    [[NSNotificationCenter defaultCenter]
     addObserverForName:UIApplicationDidFinishLaunchingNotification object:nil queue:nil
     usingBlock:^(NSNotification *notification) {
         if (notification.userInfo) {
             NSDictionary *userInfo = notification.userInfo
             [UIApplicationLaunchOptionsRemoteNotificationKey];
             [self.handler handleNotification:userInfo
                                   withAction:nil
                                    appActive:NO
                            completionHandler:nil];
         }
     }];
}

// Block to run to decide whether to show the notification
// when it is received while the app is running.
- (void)setShouldHandleNotification:(LeanplumShouldHandleNotificationBlock)block
{
    self.handler.shouldHandleNotification = block;
}

@end
