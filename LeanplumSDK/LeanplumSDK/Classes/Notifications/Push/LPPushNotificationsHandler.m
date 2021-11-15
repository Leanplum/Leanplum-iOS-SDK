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
#import <Leanplum/Leanplum-Swift.h>

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
    //TODO: move logic
//    NSString *testFormattedToken = [LeanplumUtils hexadecimalStringFromData:token];
    formattedToken = [[[formattedToken stringByReplacingOccurrencesOfString:@"<" withString:@""]
                       stringByReplacingOccurrencesOfString:@">" withString:@""]
                      stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    LPLog(LPDebug, @"Registered for notifications with Push Token: %@", formattedToken);
    
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
//    NSDictionary* settings = [notificationSettings dictionary];
//    // Send settings.
//    if ([self updateUserNotificationSettings:settings]) {
//        NSString *existingToken = [[LPPushNotificationsManager sharedManager] pushToken];
//        NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:[LPNetworkEngine notificationSettingsToRequestParams:settings]];
//        if (existingToken) {
//            params[LP_PARAM_DEVICE_PUSH_TOKEN] = existingToken;
//        }
//        [Leanplum onStartResponse:^(BOOL success) {
//            LP_END_USER_CODE
//            LPRequest *request = [LPRequestFactory setDeviceAttributesWithParams:params];
//            [[LPRequestSender sharedInstance] send:request];
//            LP_BEGIN_USER_CODE
//        }];
//    }
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
                LP_END_TRY
            }];
            [[LPRequestSender sharedInstance] send:request];
        }
        LP_BEGIN_USER_CODE
    }];
}

@end
