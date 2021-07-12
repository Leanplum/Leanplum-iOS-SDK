//
//  LPPushNotificationsHandler.m
//  Leanplum-iOS-Location
//
//  Created by Dejan Krstevski on 5.05.20.
//  Copyright © 2020 Leanplum. All rights reserved.
//

#import "LPPushNotificationsHandler.h"
#import "LPRequestFactory.h"
#import "LPRequestSender.h"
#import "LPActionContext.h"
#import "LeanplumInternal.h"
#import "LPNotificationsManager.h"

@interface LPPushNotificationsHandler()
@property (nonatomic, strong) LPCountAggregator *countAggregator;
@property (nonatomic, strong) NSDictionary *notificationHandled;
@property (nonatomic, strong) NSDate *notificationHandledTime;
@end

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
#pragma clang diagnostic ignored "-Wstrict-prototypes"
@interface UIUserNotificationSettings (LPUtil)
@property (readonly, nonatomic) NSDictionary *dictionary;
@end

@implementation UIUserNotificationSettings (LPUtil)

- (NSDictionary *)dictionary
{
    NSNumber *types = @([self types]);
    NSMutableArray *categories = [NSMutableArray array];
    for (UIMutableUserNotificationCategory *category in [self categories]) {
        if ([category identifier]) {
            // Skip categories that have no identifier.
            [categories addObject:[category identifier]];
        }
    }
    NSArray *sortedCategories = [categories sortedArrayUsingSelector:@selector(compare:)];
    NSDictionary *settings = @{LP_PARAM_DEVICE_USER_NOTIFICATION_TYPES: types,
                               LP_PARAM_DEVICE_USER_NOTIFICATION_CATEGORIES: sortedCategories};
    return settings;
}
@end

@implementation LPPushNotificationsHandler

-(instancetype)init
{
    if(self = [super init])
    {
        _countAggregator = [LPCountAggregator sharedAggregator];
    }
    return self;
}

- (void)didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    [self didReceiveRemoteNotification:userInfo fetchCompletionHandler:nil];
}

- (void)didReceiveRemoteNotification:(NSDictionary *)userInfo
              fetchCompletionHandler:(LeanplumFetchCompletionBlock __nullable)completionHandler
{
    [self didReceiveRemoteNotification:userInfo withAction:nil fetchCompletionHandler:completionHandler];
}

-(void)didReceiveRemoteNotification:(NSDictionary *)userInfo withAction:(NSString *__nullable)action fetchCompletionHandler:(LeanplumFetchCompletionBlock __nullable)completionHandler
{
    if (@available(iOS 10, *)) {
        if ([UNUserNotificationCenter currentNotificationCenter].delegate != nil) {
            if (UIApplication.sharedApplication.applicationState != UIApplicationStateBackground) {
                return;
            }
        }
    }
    
    [self.countAggregator incrementCount:@"did_receive_remote_notification"];
    
    // If app was inactive or in background, then handle notification because the user tapped it.
    if ([[UIApplication sharedApplication] applicationState] != UIApplicationStateActive) {
        [self handleNotification:userInfo
                      withAction:action
                       appActive:NO
               completionHandler:completionHandler];
        return;
    } else {
        // Application is active.
        // Hide notifications that should be muted.
        if (!userInfo[LP_KEY_PUSH_MUTE_IN_APP] &&
            !userInfo[LP_KEY_PUSH_NO_ACTION_MUTE]) {
            [self handleNotification:userInfo
                          withAction:action
                           appActive:YES
                   completionHandler:completionHandler];
            return;
        }
    }
    // Call the completion handler only for Leanplum notifications.
    NSString *messageId = [[LPNotificationsManager shared] messageIdFromUserInfo:userInfo];
    if (messageId && completionHandler) {
        completionHandler(UIBackgroundFetchResultNoData);
    }
}

-(void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)token
{
    LP_TRY
    if (![[UIApplication sharedApplication] respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        // In pre-ios 8, didRegisterForRemoteNotificationsWithDeviceToken has combined semantics with
        // didRegisterUserNotificationSettings and the ask to push will have been triggered.
        [self leanplum_disableAskToAsk];
    }

    // Format push token.
    NSString *formattedToken = [[LPNotificationsManager shared] hexadecimalStringFromData:token];
    formattedToken = [[[formattedToken stringByReplacingOccurrencesOfString:@"<" withString:@""]
                       stringByReplacingOccurrencesOfString:@">" withString:@""]
                      stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    NSMutableDictionary* deviceAttributeParams = [[NSMutableDictionary alloc] init];
    // Send push token if we don't have one and when the token changed.
    // We no longer send in start's response because saved push token will be send in start too.
    NSString *existingToken = [[LPPushNotificationsManager sharedManager] pushToken];
    if (!existingToken || ![existingToken isEqualToString:formattedToken]) {
        [[LPPushNotificationsManager sharedManager] updatePushToken:formattedToken];
        deviceAttributeParams[LP_PARAM_DEVICE_PUSH_TOKEN] = formattedToken;
    }
    // Get the push types if changed
    NSDictionary* settings = [[UIApplication sharedApplication].currentUserNotificationSettings dictionary];
    if ([self updateUserNotificationSettings:settings]) {
        [deviceAttributeParams addEntriesFromDictionary:[LPNetworkEngine notificationSettingsToRequestParams:settings]];
    }
    
    // If there are changes to the push token and/or the push types, send a request
    if (deviceAttributeParams.count > 0) {
        [Leanplum onStartResponse:^(BOOL success) {
            LP_END_USER_CODE
            LPRequest *request = [LPRequestFactory setDeviceAttributesWithParams:deviceAttributeParams];
            [[LPRequestSender sharedInstance] send:request];
            LP_BEGIN_USER_CODE
        }];
    }
    LP_END_TRY
}

- (void)didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    LP_TRY
    [self leanplum_disableAskToAsk];
    [[LPPushNotificationsManager sharedManager] removePushToken];
    LP_END_TRY
}

- (void)didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings
{
    LP_TRY
    [self leanplum_disableAskToAsk];
    [self sendUserNotificationSettingsIfChanged:notificationSettings];
    LP_END_TRY
}

#pragma mark - Notification Settings
- (BOOL)updateUserNotificationSettings:(NSDictionary *)newSettings
{
    NSString *settingsKey = [[LPPushNotificationsManager sharedManager] leanplum_createUserNotificationSettingsKey];
    NSDictionary *existingSettings = [[NSUserDefaults standardUserDefaults] dictionaryForKey:settingsKey];
    if (![existingSettings isEqualToDictionary:newSettings]) {
        [[NSUserDefaults standardUserDefaults] setObject:newSettings forKey:settingsKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
        return YES;
    }
    
    return NO;
}

- (NSDictionary *)currentUserNotificationSettings
{
    NSString *settingsKey = [[LPPushNotificationsManager sharedManager] leanplum_createUserNotificationSettingsKey];
    NSDictionary *existingSettings = [[NSUserDefaults standardUserDefaults] dictionaryForKey:settingsKey];
    return existingSettings;
}

#pragma mark - Push Notifications
- (void)sendUserNotificationSettingsIfChanged:(UIUserNotificationSettings *)notificationSettings
{
    NSDictionary* settings = [notificationSettings dictionary];
    // Send settings.
    if ([self updateUserNotificationSettings:settings]) {
        NSString *existingToken = [[LPPushNotificationsManager sharedManager] pushToken];
        NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:[LPNetworkEngine notificationSettingsToRequestParams:settings]];
        if (existingToken) {
            params[LP_PARAM_DEVICE_PUSH_TOKEN] = existingToken;
        }
        [Leanplum onStartResponse:^(BOOL success) {
            LP_END_USER_CODE
            LPRequest *request = [LPRequestFactory setDeviceAttributesWithParams:params];
            [[LPRequestSender sharedInstance] send:request];
            LP_BEGIN_USER_CODE
        }];
    }
}

- (void)leanplum_disableAskToAsk
{
    Class userMessageTemplatesClass = NSClassFromString(@"LPMessageTemplates");
    if (userMessageTemplatesClass &&
        [[userMessageTemplatesClass sharedTemplates] respondsToSelector:@selector(disableAskToAsk)]) {
        [[userMessageTemplatesClass sharedTemplates] disableAskToAsk];
    } else {
        [[LPMessageTemplatesClass sharedTemplates] disableAskToAsk];
    }
}
#pragma clang diagnostic pop

#pragma mark - Push Notifications - Handlers

// Handles the notification.
// Makes sure the data is loaded, and then displays the notification.
- (void)handleNotification:(NSDictionary *)userInfo
                withAction:(NSString *__nullable)action
                 appActive:(BOOL)active
         completionHandler:(LeanplumFetchCompletionBlock __nullable)completionHandler
{
    // Don't handle non-Leanplum notifications.
    NSString *messageId = [[LPNotificationsManager shared] messageIdFromUserInfo:userInfo];
    if (messageId == nil) {
        return;
    }
    
    void (^onContent)(void) = ^{
        if (completionHandler) {
            completionHandler(UIBackgroundFetchResultNewData);
        }
        
        BOOL hasAlert = userInfo[@"aps"][@"alert"] != nil;
        if (hasAlert) {
            [self maybePerformNotificationActions:userInfo action:action active:active];
        }
    };
    
    LPLog(LPDebug, @"Push RECEIVED");

    [Leanplum onStartIssued:^() {
        if ([self areActionsEmbedded:userInfo]) {
            onContent();
        } else {
            [self requireMessageContent:messageId withCompletionBlock:onContent];
        }
    }];
}

// Performs the notification action if
// (a) The app wasn't active before
// (b) The user accepts that they want to view the notification
- (void)maybePerformNotificationActions:(NSDictionary *)userInfo
                                 action:(NSString *)action
                                 active:(BOOL)active
{
    // Do not perform the action if the app is in background
    if (UIApplication.sharedApplication.applicationState == UIApplicationStateBackground) {
        return;
    }

    // Don't handle duplicate notifications.
    if ([self isDuplicateNotification:userInfo]) {
        return;
    }
    
    if (UIApplication.sharedApplication.applicationState == UIApplicationStateActive) {
        if (userInfo[LP_KEY_PUSH_NO_ACTION] ||
            userInfo[LP_KEY_PUSH_NO_ACTION_MUTE]) {
            return;
        }
    }
    
    LPLog(LPDebug, @"Push OPENED");
    LPLog(LPInfo, @"Handling push notification");
    NSString *messageId = [[LPNotificationsManager shared] messageIdFromUserInfo:userInfo];
    NSString *actionName;
    if (action == nil) {
        actionName = LP_VALUE_DEFAULT_PUSH_ACTION;
    } else {
        actionName = [NSString stringWithFormat:@"iOS options.Custom actions.%@", action];
    }
    LPActionContext *context;
    if ([self areActionsEmbedded:userInfo]) {
        NSMutableDictionary *args = [NSMutableDictionary dictionary];
        if (action) {
            args[actionName] = userInfo[LP_KEY_PUSH_CUSTOM_ACTIONS][action];
        } else {
            args[actionName] = userInfo[LP_KEY_PUSH_ACTION];
        }
        context = [LPActionContext actionContextWithName:LP_PUSH_NOTIFICATION_ACTION
                                                    args:args
                                               messageId:messageId];
        context.preventRealtimeUpdating = YES;
    } else {
        context = [Leanplum createActionContextForMessageId:messageId];
    }
    [context maybeDownloadFiles];

    LeanplumVariablesChangedBlock handleNotificationBlock = ^{
        [context runTrackedActionNamed:actionName];
    };

    if (!active) {
        handleNotificationBlock();
    } else {
        if (self.shouldHandleNotification) {
            self.shouldHandleNotification(userInfo, handleNotificationBlock);
        } else {
            if (userInfo[LP_KEY_PUSH_NO_ACTION] ||
                userInfo[LP_KEY_PUSH_NO_ACTION_MUTE]) {
                handleNotificationBlock();
            } else {
                if ([Leanplum hasStarted]) {
                    id message = userInfo[@"aps"][@"alert"];
                    if ([message isKindOfClass:NSDictionary.class]) {
                        message = message[@"body"];
                    }
                    if (message) {
                        [LPUIAlert showWithTitle:APP_NAME
                                         message:message
                               cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                               otherButtonTitles:@[NSLocalizedString(@"View", nil)]
                                           block:^(NSInteger buttonIndex) {
                                               if (buttonIndex == 1) {
                                                   handleNotificationBlock();
                                               }
                                           }];
                    }
                }
            }
        }
    }
}

- (void)requireMessageContent:(NSString *)messageId
          withCompletionBlock:(LeanplumVariablesChangedBlock)onCompleted
{
    [Leanplum onceVariablesChangedAndNoDownloadsPending:^{
        LP_END_USER_CODE
        if (!messageId || [LPVarCache sharedCache].messages[messageId]) {
            if (onCompleted) {
                onCompleted();
            }
        } else {
            // Try downloading the messages again if it doesn't exist.
            // Maybe the message was created while the app was running.
            LPRequest *request = [[LPRequestFactory getVarsWithParams:@{
                                                                     LP_PARAM_INCLUDE_DEFAULTS: @(NO),
                                                                     LP_PARAM_INCLUDE_MESSAGE_ID: messageId
                                                                    }]
                                                    andRequestType:Immediate];
            [request onResponse:^(id<LPNetworkOperationProtocol> operation, NSDictionary *response) {
                LP_TRY
                NSDictionary *values = response[LP_KEY_VARS];
                NSDictionary *messages = response[LP_KEY_MESSAGES];
                NSArray *variants = response[LP_KEY_VARIANTS];
                NSDictionary *regions = response[LP_KEY_REGIONS];
                NSString *varsJson = [LPJSON stringFromJSON:[response valueForKey:LP_KEY_VARS]];
                NSString *varsSignature = response[LP_KEY_VARS_SIGNATURE];
                NSArray *localCaps = response[LP_KEY_LOCAL_CAPS];
                
                if (![LPConstantsState sharedState].canDownloadContentMidSessionInProduction ||
                    [values isEqualToDictionary:[LPVarCache sharedCache].diffs]) {
                    values = nil;
                    varsJson = nil;
                    varsSignature = nil;
                }
                if ([messages isEqualToDictionary:[LPVarCache sharedCache].messageDiffs]) {
                    messages = nil;
                }
                if ([regions isEqualToDictionary:[LPVarCache sharedCache].regions]) {
                    regions = nil;
                }
                if (values || messages || regions) {
                    [[LPVarCache sharedCache] applyVariableDiffs:values
                                                        messages:messages
                                                        variants:variants
                                                       localCaps:localCaps
                                                         regions:regions
                                                variantDebugInfo:nil
                                                        varsJson:varsJson
                                                   varsSignature:varsSignature];
                    if (onCompleted) {
                        onCompleted();
                    }
                }
                LP_END_TRY
             }];
            [[LPRequestSender sharedInstance] send:request];
        }
        LP_BEGIN_USER_CODE
    }];
}

#pragma mark - Push Notifications UNNotificationFramework

- (void)willPresentNotification:(UNNotification *)notification
          withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler
{
    LP_TRY
    // this will be called iff app is active and in foreground visible to the user.
    // we will have to check whether we gonna show the action or not.
    NSDictionary* userInfo = [[[notification request] content] userInfo];
    [self handleWillPresentNotification:userInfo withCompletionHandler:completionHandler];
    LP_END_TRY
}

- (void)didReceiveNotificationResponse:(UNNotificationResponse *)response
                 withCompletionHandler:(void (^)(void))completionHandler API_AVAILABLE(ios(10.0))
{
    NSDictionary *userInfo = response.notification.request.content.userInfo;
    LPInternalState *state = [LPInternalState sharedState];
    state.calledHandleNotification = NO;

    LeanplumFetchCompletionBlock leanplumCompletionHandler =
    ^(LeanplumUIBackgroundFetchResult result) {
        completionHandler();
    };

    // Prevents handling the notification twice if the original method calls handleNotification
    // explicitly.
    if (!state.calledHandleNotification) {
        LP_TRY
        [self handleNotificationResponse:userInfo
                       completionHandler:leanplumCompletionHandler];
        LP_END_TRY
    }
    state.calledHandleNotification = NO;
}

// Will be called when user taps on notification from status bar iff UNUserNotificationCenterDelegate is implemented in UIApplicationDelegate.
// We need to check first whether the action is muted, and depending on it show or silence the action.
- (void)handleNotificationResponse:(NSDictionary *)userInfo
                 completionHandler:(LeanplumFetchCompletionBlock)completionHandler
{
    NSString *messageId = [[LPNotificationsManager shared] messageIdFromUserInfo:userInfo];
    if (messageId == nil) {
        return;
    }

    void (^onContent)(void) = ^{
        if (completionHandler) {
            completionHandler(UIBackgroundFetchResultNewData);
        }
        BOOL hasAlert = userInfo[@"aps"][@"alert"] != nil;
        if (hasAlert) {
            BOOL active = UIApplication.sharedApplication.applicationState == UIApplicationStateActive;
            [self maybePerformNotificationActions:userInfo action:nil active:active];
        }
    };
    
    LPLog(LPDebug, @"Push RECEIVED");
    
    if ([[UIApplication sharedApplication] applicationState] != UIApplicationStateActive) {
        [Leanplum onStartIssued:^() {
            if ([self areActionsEmbedded:userInfo]) {
                onContent();
            } else {
                [self requireMessageContent:messageId withCompletionBlock:onContent];
            }
        }];
    } else {
        if (messageId && completionHandler) {
            completionHandler(UIBackgroundFetchResultNoData);
        }
    }
}

- (void)handleWillPresentNotification:(NSDictionary *)userInfo
{
    if(@available(iOS 10, *)) {
        [self handleWillPresentNotification:userInfo withCompletionHandler:nil];
    }
}

// Will be called when user receives notification and app is in foreground iff UNUserNotificationCenterDelegate is implemented in UIApplicationDelegate.
// We need to check first whether the action is muted, and depending on it show or silence the action.
- (void)handleWillPresentNotification:(NSDictionary *)userInfo
                withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler API_AVAILABLE(ios(10.0))

{
    NSString *messageId = [[LPNotificationsManager shared] messageIdFromUserInfo:userInfo];
    if (messageId == nil) {
        return;
    }

    void (^onContent)(void) = ^{
        if (completionHandler) {
            completionHandler(UNNotificationPresentationOptionNone);
        }
        BOOL hasAlert = userInfo[@"aps"][@"alert"] != nil;
        if (hasAlert) {
            BOOL active = UIApplication.sharedApplication.applicationState == UIApplicationStateActive;
            [self maybePerformNotificationActions:userInfo action:nil active:active];
        }
    };
    
    LPLog(LPDebug, @"Push RECEIVED");

    if (!userInfo[LP_KEY_PUSH_MUTE_IN_APP] && !userInfo[LP_KEY_PUSH_NO_ACTION_MUTE]) {
        [Leanplum onStartIssued:^() {
            if ([self areActionsEmbedded:userInfo]) {
                onContent();
            } else {
                [self requireMessageContent:messageId withCompletionBlock:onContent];
            }
        }];
    } else {
        if (messageId && completionHandler) {
            completionHandler(UNNotificationPresentationOptionNone);
        }
    }
}

- (BOOL)areActionsEmbedded:(NSDictionary *)userInfo
{
    return userInfo[LP_KEY_PUSH_ACTION] != nil ||
        userInfo[LP_KEY_PUSH_CUSTOM_ACTIONS] != nil;
}

- (BOOL)isDuplicateNotification:(NSDictionary *)userInfo
{
    if ([self.notificationHandled isEqualToDictionary:userInfo] &&
        [[NSDate date] timeIntervalSinceDate:self.notificationHandledTime] < 10.0) {
        return YES;
    }

    self.notificationHandled = userInfo;
    self.notificationHandledTime = [NSDate date];
    return NO;
}

@end
