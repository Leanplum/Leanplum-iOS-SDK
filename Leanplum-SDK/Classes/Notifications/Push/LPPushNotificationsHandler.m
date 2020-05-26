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
#import "LeanplumRequest.h"
#import "LPActionContext.h"
#import "LeanplumInternal.h"
#import "LPNotificationsManager.h"

@interface LPPushNotificationsHandler()
@property (nonatomic, strong) LPCountAggregator *countAggregator;
@property (nonatomic, strong) NSString *notificationHandled;
@property (nonatomic, strong) NSDate *notificationHandledTime;
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
    [self.countAggregator incrementCount:@"did_receive_remote_notification"];
    
    // If app was inactive, then handle notification because the user tapped it.
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
    
    // Send push token if we don't have one and when the token changed.
    // We no longer send in start's response because saved push token will be send in start too.
    NSString *existingToken = [[LPPushNotificationsManager sharedManager] pushToken];
    if (!existingToken || ![existingToken isEqualToString:formattedToken]) {
        
        [[LPPushNotificationsManager sharedManager] updatePushToken:formattedToken];
        
        LPRequestFactory *reqFactory = [[LPRequestFactory alloc]
                                        initWithFeatureFlagManager:[LPFeatureFlagManager sharedManager]];
        
        id<LPRequesting> request = [reqFactory
                                    setDeviceAttributesWithParams:@{LP_PARAM_DEVICE_PUSH_TOKEN: formattedToken}];
        [[LPRequestSender sharedInstance] send:request];
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

#pragma mark - Push Notifications
- (void)sendUserNotificationSettingsIfChanged:(UIUserNotificationSettings *)notificationSettings
{
    // Send settings.
    NSString *settingsKey = [[LPPushNotificationsManager sharedManager] leanplum_createUserNotificationSettingsKey];
    NSDictionary *existingSettings = [[NSUserDefaults standardUserDefaults] dictionaryForKey:settingsKey];
    NSNumber *types = @([notificationSettings types]);
    NSMutableArray *categories = [NSMutableArray array];
    for (UIMutableUserNotificationCategory *category in [notificationSettings categories]) {
        if ([category identifier]) {
            // Skip categories that have no identifier.
            [categories addObject:[category identifier]];
        }
    }
    NSArray *sortedCategories = [categories sortedArrayUsingSelector:@selector(compare:)];
    NSDictionary *settings = @{LP_PARAM_DEVICE_USER_NOTIFICATION_TYPES: types,
                               LP_PARAM_DEVICE_USER_NOTIFICATION_CATEGORIES: sortedCategories};
    if (![existingSettings isEqualToDictionary:settings]) {
        [[NSUserDefaults standardUserDefaults] setObject:settings forKey:settingsKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
        NSString *existingToken = [[LPPushNotificationsManager sharedManager] pushToken];
        NSMutableDictionary *params = [@{
                LP_PARAM_DEVICE_USER_NOTIFICATION_TYPES: types,
                LP_PARAM_DEVICE_USER_NOTIFICATION_CATEGORIES:
                      [LPJSON stringFromJSON:sortedCategories] ?: @""} mutableCopy];
        if (existingToken) {
            params[LP_PARAM_DEVICE_PUSH_TOKEN] = existingToken;
        }
        [Leanplum onStartResponse:^(BOOL success) {
            LP_END_USER_CODE
            LPRequestFactory *reqFactory = [[LPRequestFactory alloc]
                                            initWithFeatureFlagManager:[LPFeatureFlagManager sharedManager]];
            id<LPRequesting> request = [reqFactory setDeviceAttributesWithParams:params];
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
            UIApplicationState appState = [[UIApplication sharedApplication] applicationState];
            if (appState != UIApplicationStateBackground) {
                [self maybePerformNotificationActions:userInfo action:action active:active];
            }
        }
    };

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
    // Don't handle duplicate notifications.
    if ([self isDuplicateNotification:userInfo]) {
        return;
    }

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
            id<LPRequesting> request = [LeanplumRequest
                                    post:LP_METHOD_GET_VARS
                                    params:@{
                                             LP_PARAM_INCLUDE_DEFAULTS: @(NO),
                                             LP_PARAM_INCLUDE_MESSAGE_ID: messageId
                                             }];
            [request onResponse:^(id<LPNetworkOperationProtocol> operation, NSDictionary *response) {
                LP_TRY
                NSDictionary *values = response[LP_KEY_VARS];
                NSDictionary *messages = response[LP_KEY_MESSAGES];
                NSArray *updateRules = response[LP_KEY_UPDATE_RULES];
                NSArray *eventRules = response[LP_KEY_EVENT_RULES];
                NSArray *variants = response[LP_KEY_VARIANTS];
                NSDictionary *regions = response[LP_KEY_REGIONS];
                if (![LPConstantsState sharedState].canDownloadContentMidSessionInProduction ||
                    [values isEqualToDictionary:[LPVarCache sharedCache].diffs]) {
                    values = nil;
                }
                if ([messages isEqualToDictionary:[LPVarCache sharedCache].messageDiffs]) {
                    messages = nil;
                }
                if ([updateRules isEqualToArray:[LPVarCache sharedCache].updateRulesDiffs]) {
                    updateRules = nil;
                }
                if ([eventRules isEqualToArray:[LPVarCache sharedCache].updateRulesDiffs]) {
                    eventRules = nil;
                }
                if ([regions isEqualToDictionary:[LPVarCache sharedCache].regions]) {
                    regions = nil;
                }
                if (values || messages || updateRules || eventRules || regions) {
                    [[LPVarCache sharedCache] applyVariableDiffs:values
                                          messages:messages
                                       updateRules:updateRules
                                        eventRules:eventRules
                                          variants:variants
                                           regions:regions
                                  variantDebugInfo:nil];
                    if (onCompleted) {
                        onCompleted();
                    }
                }
                LP_END_TRY
             }];
            [[LPRequestSender sharedInstance] sendIfConnected:request];
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
            [self maybePerformNotificationActions:userInfo action:nil active:NO];
        }
    };

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
            completionHandler(UIBackgroundFetchResultNoData);
        }
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
            [self maybePerformNotificationActions:userInfo action:nil active:YES];
        }
    };

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
    if ([self.notificationHandled isEqualToString:[LPJSON stringFromJSON:userInfo]] &&
        [[NSDate date] timeIntervalSinceDate:self.notificationHandledTime] < 10.0) {
        return YES;
    }

    self.notificationHandled = [LPJSON stringFromJSON:userInfo];
    self.notificationHandledTime = [NSDate date];
    return NO;
}

@end
