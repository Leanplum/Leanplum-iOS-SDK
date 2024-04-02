//
//  Leanplum.h
//  Leanplum iOS SDK Version 2.0.6
//
//  Copyright (c) 2022 Leanplum, Inc. All rights reserved.
//
//  Licensed to the Apache Software Foundation (ASF) under one
//  or more contributor license agreements.  See the NOTICE file
//  distributed with this work for additional information
//  regarding copyright ownership.  The ASF licenses this file
//  to you under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing,
//  software distributed under the License is distributed on an
//  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
//  KIND, either express or implied.  See the License for the
//  specific language governing permissions and limitations
//  under the License.

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <UserNotifications/UserNotifications.h>
#import "LPInbox.h"
#import "LPActionArg.h"
#import "LPVar.h"
#import "LPEnumConstants.h"
#import "Leanplum_WebSocket.h"
#import "LPNetworkOperation.h"
#import "LPUtils.h"
#import "LPResponse.h"
#import "Leanplum_SocketIO.h"
#import "LeanplumSocket.h"
#import "LeanplumCompatibility.h"
#import "LPSwizzle.h"
#import "LPEventDataManager.h"
#import "LPEventCallbackManager.h"
#import "LPAppIconManager.h"
#import "Leanplum_AsyncSocket.h"
#import "LPRevenueManager.h"
#import "LPContextualValues.h"
#import "LPFeatureFlagManager.h"
#import "LPConstants.h"
#import "LPKeychainWrapper.h"
#import "LPNetworkFactory.h"
#import "LPCountAggregator.h"
#import "LPFileManager.h"
#import "LPVarCache.h"
#import "LPDatabase.h"
#import "NSString+MD5Addition.h"
#import "FileMD5Hash.h"
#import "LPJSON.h"
#import "LPNetworkProtocol.h"
#import "LPMessageTemplates.h"
#import "LPFeatureFlags.h"
#import "UIDevice+IdentifierAddition.h"
#import "NSTimer+Blocks.h"
#import "LPEventCallback.h"
#import "LPNetworkEngine.h"
#import "LPAES.h"
#import "LPLogManager.h"
#import "LPRequestSenderTimer.h"
#import "LPRequestSender.h"
#import "CleverTapInstanceCallback.h"

NS_ASSUME_NONNULL_BEGIN

#define _LP_DEFINE_HELPER(name,val,type) LPVar* name; \
static void __attribute__((constructor)) initialize_##name() { \
@autoreleasepool { \
name = [LPVar define:[@#name stringByReplacingOccurrencesOfString:@"_" withString:@"."] with##type:val]; \
} \
}

/**
 * @defgroup Macros Variable Macros
 * Use these macros to define variables inside your app.
 * Underscores within variable names will nest variables within groups.
 * To define variables in a more custom way, copy and modify
 * the template above in your own code.
 * @see LPVar
 * @{
 */
#define DEFINE_VAR_INT(name,val) _LP_DEFINE_HELPER(name, val, Int)
#define DEFINE_VAR_BOOL(name,val) _LP_DEFINE_HELPER(name, val, Bool)
#define DEFINE_VAR_STRING(name,val) _LP_DEFINE_HELPER(name, val, String)
#define DEFINE_VAR_NUMBER(name,val) _LP_DEFINE_HELPER(name, val, Number)
#define DEFINE_VAR_FLOAT(name,val) _LP_DEFINE_HELPER(name, val, Float)
#define DEFINE_VAR_CGFLOAT(name,val) _LP_DEFINE_HELPER(name, val, CGFloat)
#define DEFINE_VAR_DOUBLE(name,val) _LP_DEFINE_HELPER(name, val, Double)
#define DEFINE_VAR_SHORT(name,val) _LP_DEFINE_HELPER(name, val, Short)
#define DEFINE_VAR_LONG(name,val) _LP_DEFINE_HELPER(name, val, Long)
#define DEFINE_VAR_CHAR(name,val) _LP_DEFINE_HELPER(name, val, Char)
#define DEFINE_VAR_LONG_LONG(name,val) _LP_DEFINE_HELPER(name, val, LongLong)
#define DEFINE_VAR_INTEGER(name,val) _LP_DEFINE_HELPER(name, val, Integer)
#define DEFINE_VAR_UINT(name,val) _LP_DEFINE_HELPER(name, val, UnsignedInt)
#define DEFINE_VAR_UCHAR(name,val) _LP_DEFINE_HELPER(name, val, UnsignedChar)
#define DEFINE_VAR_ULONG(name,val) _LP_DEFINE_HELPER(name, val, UnsignedLong)
#define DEFINE_VAR_UINTEGER(name,val) _LP_DEFINE_HELPER(name, val, UnsignedInteger)
#define DEFINE_VAR_USHORT(name,val) _LP_DEFINE_HELPER(name, val, UnsignedShort)
#define DEFINE_VAR_ULONGLONG(name,val) _LP_DEFINE_HELPER(name, val, UnsignedLongLong)
#define DEFINE_VAR_UNSIGNED_INT(name,val) _LP_DEFINE_HELPER(name, val, UnsignedInt)
#define DEFINE_VAR_UNSIGNED_INTEGER(name,val) _LP_DEFINE_HELPER(name, val, UnsignedInteger)
#define DEFINE_VAR_UNSIGNED_CHAR(name,val) _LP_DEFINE_HELPER(name, val, UnsignedChar)
#define DEFINE_VAR_UNSIGNED_LONG(name,val) _LP_DEFINE_HELPER(name, val, UnsignedLong)
#define DEFINE_VAR_UNSIGNED_LONG_LONG(name,val) _LP_DEFINE_HELPER(name, val, UnsignedLongLong)
#define DEFINE_VAR_UNSIGNED_SHORT(name,val) _LP_DEFINE_HELPER(name, val, UnsignedShort)
#define DEFINE_VAR_FILE(name,filename) _LP_DEFINE_HELPER(name, filename, File)
#define DEFINE_VAR_DICTIONARY(name,dict) _LP_DEFINE_HELPER(name, dict, Dictionary)
#define DEFINE_VAR_ARRAY(name,array) _LP_DEFINE_HELPER(name, array, Array)
#define DEFINE_VAR_COLOR(name,val) _LP_DEFINE_HELPER(name, val, Color)

#define DEFINE_VAR_DICTIONARY_WITH_OBJECTS_AND_KEYS(name,...) LPVar* name; \
static void __attribute__((constructor)) initialize_##name() { \
@autoreleasepool { \
name = [LPVar define:[@#name stringByReplacingOccurrencesOfString:@"_" withString:@"."] withDictionary:[NSDictionary dictionaryWithObjectsAndKeys:__VA_ARGS__]]; \
} \
}

#define DEFINE_VAR_ARRAY_WITH_OBJECTS(name,...) LPVar* name; \
static void __attribute__((constructor)) initialize_##name() { \
@autoreleasepool { \
name = [LPVar define:[@#name stringByReplacingOccurrencesOfString:@"_" withString:@"."] withArray:[NSArray arrayWithObjects:__VA_ARGS__]]; \
} \
}
/**@}*/

// Prevent circular reference
@class LPDeferrableAction;
@class LPActionContext;
@class SKPaymentTransaction;
@class NSExtensionContext;

/**
 * @defgroup _ Callback Blocks
 * Those blocks are used when you define callbacks.
 * @{
 */
typedef void (^LeanplumStartBlock)(BOOL success);
typedef void (^LeanplumSetLocationBlock)(BOOL success);
// Returns whether the action was handled.
typedef BOOL (^LeanplumActionBlock)(LPActionContext* context);
typedef void (^LeanplumHandleNotificationBlock)(void);
typedef void (^LeanplumShouldHandleNotificationBlock)(NSDictionary *userInfo, LeanplumHandleNotificationBlock response);
typedef void (^LeanplumCleverTapNotificationBlock)(BOOL openDeeplink);
typedef void (^LeanplumHandleCleverTapNotificationBlock)(NSDictionary *userInfo,
                                                         BOOL isNotificationOpen,
                                                         LeanplumCleverTapNotificationBlock response);
typedef void (^LeanplumPushSetupBlock)(void);
/**@}*/

/**
 * Leanplum Action Kind Message types
 * This is a bit-field. To choose both kinds, use
 * kLeanplumActionKindMessage | kLeanplumActionKindAction
 */
typedef NS_OPTIONS(NSUInteger, LeanplumActionKind) {
    kLeanplumActionKindMessage = 0b1,
    kLeanplumActionKindAction = 0b10,
} NS_SWIFT_NAME(LeanplumActionKind);

#define LP_PURCHASE_EVENT @"Purchase"

/**
 * Leanplum Environment value for development, used in Leanplum-Info.plist
 */
extern NSString *const kEnvDevelopment;

/**
 * Leanplum Environment value for production, used in Leanplum-Info.plist
 */
extern NSString *const kEnvProduction;

@interface Leanplum : NSObject

- (instancetype)init NS_UNAVAILABLE;

/**
 * Optional. Sets the API server. The API path is of the form http[s]://hostname/servletName
 * @param hostName The name of the API host, such as api.leanplum.com
 * @param apiPath The name of the API path, such as api
 * @param ssl Whether to use SSL
 */
+ (void)setApiHostName:(NSString *)hostName withPath:(NSString *)apiPath usingSsl:(BOOL)ssl
NS_SWIFT_NAME(setApiHostName(_:apiPath:ssl:));

/**
 * Optional. Sets socket hostname and port
 * @param hostName The name of the socket host
 * @param port port of the socket
 */
+ (void)setSocketHostName:(NSString *)hostName withPortNumber:(int)port
NS_SWIFT_NAME(setSocketHostName(_:port:));

/**
 * Optional. Adjusts the network timeouts.
 * The default timeout is 10 seconds for requests, and 15 seconds for file downloads.
 * @{
 */
+ (void)setNetworkTimeoutSeconds:(int)seconds;
+ (void)setNetworkTimeoutSeconds:(int)seconds forDownloads:(int)downloadSeconds;
/**@}*/

/**
* Sets log level through the Leanplum SDK
*/
+ (void)setLogLevel:(LPLogLevel)level;

/**
 * Sets a custom event name for in-app purchase tracking. Default: Purchase.
 */
+ (void)setInAppPurchaseEventName:(NSString *)event;

/**
 * @{
 * Must call either this or {@link setAppId:withProductionKey:}
 * before issuing any calls to the API, including start.
 * @param appId Your app ID.
 * @param accessKey Your development key.
 */
+ (void)setAppId:(NSString *)appId withDevelopmentKey:(NSString *)accessKey
NS_SWIFT_NAME(setAppId(_:developmentKey:));

/**
 * Must call either this or {@link Leanplum::setAppId:withDevelopmentKey:}
 * before issuing any calls to the API, including start.
 * @param appId Your app ID.
 * @param accessKey Your production key.
 */
+ (void)setAppId:(NSString *)appId withProductionKey:(NSString *)accessKey
NS_SWIFT_NAME(setAppId(_:productionKey:));
/**@}*/

/**
 * Sets the corresponding key based on the environment. Call only if initialising using plist.
 * @param env "development" or "production" - kEnvDevelopment or kEnvProduction
 */
+ (void)setAppEnvironment:(NSString *)env;

/**
 * Apps running as extensions need to call this before start.
 * @param context The current extensionContext. You can get this from UIViewController.
 */
+ (void)setExtensionContext:(NSExtensionContext *)context;

/**
 * Sets a custom device ID. For example, you may want to pass the advertising ID to do attribution.
 * By default, the device ID is the identifier for vendor.
 */
+ (void)setDeviceId:(NSString *)deviceId;

/**
 * By default, Leanplum reports the version of your app using CFBundleVersion, which
 * can be used for reporting and targeting on the Leanplum dashboard.
 * If you wish to use CFBundleShortVersionString or any other string as the version,
 * you can call this before your call to [Leanplum start]
 */
+ (void)setAppVersion:(NSString *)appVersion;

/**
 * Syncs resources between Leanplum and the current app.
 * You should only call this once, and before {@link start}.
 * @param async Whether the call should be asynchronous. Resource syncing can take 1-2 seconds to
 *     index the app's resources. If async is set, resources may not be available immediately
 *     when the app starts.
 */
+ (void)syncResourcesAsync:(BOOL)async;

/**
 * Syncs resources between Leanplum and the current app.
 * You should only call this once, and before {@link start}.
 * @param async Whether the call should be asynchronous. Resource syncing can take 1-2 seconds to
 *     index the app's resources. If async is set, resources may not be available immediately
 *     when the app starts.
 * @param patternsToIncludeOrNil Limit paths to only those matching at least one pattern in this
 *     list. Supply nil to indicate no inclusion patterns. Paths are relative to the app's bundle.
 * @param patternsToExcludeOrNil Exclude paths matching at least one of these patterns.
 *     Supply nil to indicate no exclusion patterns.
 * @param async Whether the call should be asynchronous. Resource syncing can take 1-2 seconds to
 *     index the app's resources. If async is set, resources may not be available immediately
 *     when the app starts.
 */
+ (void)syncResourcePaths:(nullable NSArray<NSString *> *)patternsToIncludeOrNil
                excluding:(nullable NSArray<NSString *> *)patternsToExcludeOrNil
                    async:(BOOL)async;
/**@}*/

/**
 * @{
 * Call this when your application starts.
 * This will initiate a call to Leanplum's servers to get the values
 * of the variables used in your app.
 */
+ (void)start;

+ (void)startWithResponseHandler:(LeanplumStartBlock)response
NS_SWIFT_NAME(start(completion:));

+ (void)startWithUserAttributes:(NSDictionary<NSString *, id> *)attributes
NS_SWIFT_NAME(start(attributes:));

+ (void)startWithUserId:(NSString *)userId
NS_SWIFT_NAME(start(userId:));

+ (void)startWithUserId:(NSString *)userId
        responseHandler:(nullable LeanplumStartBlock)response
NS_SWIFT_NAME(start(userId:completion:));

+ (void)startWithUserId:(NSString *)userId
         userAttributes:(NSDictionary<NSString *, id> *)attributes
NS_SWIFT_UNAVAILABLE("Use start(userId:attributes:completion:");

+ (void)startWithUserId:(nullable NSString *)userId
         userAttributes:(nullable NSDictionary<NSString *, id> *)attributes
        responseHandler:(nullable LeanplumStartBlock)startResponse
NS_SWIFT_NAME(start(userId:attributes:completion:));
/**@}*/

/**
 * @{
 * Returns whether or not Leanplum has finished starting.
 */
+ (BOOL)hasStarted;

/**
 * Returns whether or not Leanplum has finished starting and the device is registered
 * as a developer.
 */
+ (BOOL)hasStartedAndRegisteredAsDeveloper;
/**@}*/

/**
 * Block to call when the start call finishes, and variables are returned
 * back from the server. Calling this multiple times will call each block
 * in succession.
 */
+ (void)onStartResponse:(LeanplumStartBlock)block;

/**
 * Block to call when the variables receive new values from the server.
 * This will be called on start, and also later on if the user is in an experiment
 * that can update in realtime.
 */
+ (void)onVariablesChanged:(LeanplumVariablesChangedBlock)block;

/**
 * Block to call when no more file downloads are pending (either when
 * no files needed to be downloaded or all downloads have been completed).
 */
+ (void)onVariablesChangedAndNoDownloadsPending:(LeanplumVariablesChangedBlock)block;

/**
 * Block to call ONCE when no more file downloads are pending (either when
 * no files needed to be downloaded or all downloads have been completed).
 */
+ (void)onceVariablesChangedAndNoDownloadsPending:(LeanplumVariablesChangedBlock)block;

/**
 * Clears cached values for messages, variables and test assignments.
 * Use sparingly as if the app is updated, you'll have to deal with potentially
 * inconsistent state or user experience.
 */
+ (void)clearUserContent;

/// Defines new action and message types to be performed at points set up on the Leanplum dashboard.
+ (void)defineAction:(NSString *)name
              ofKind:(LeanplumActionKind)kind
       withArguments:(NSArray<LPActionArg *> *)args
         withOptions:(NSDictionary<NSString *, id> *)options
      presentHandler:(nullable LeanplumActionBlock)presentHandler
      dismissHandler:(nullable LeanplumActionBlock)dismissHandler
NS_SWIFT_NAME(defineAction(name:kind:args:options:present:dismiss:));

/**
 * Checks if message should be suppressed based on the local IAM caps.
 * @param context The message context to check.
 * @return True if message should  be suppressed, false otherwise.
*/
+ (BOOL)shouldSuppressMessage:(LPActionContext *)context;

+ (void)applicationDidFinishLaunchingWithOptions:(NSDictionary<UIApplicationLaunchOptionsKey, id> *)launchOptions;
+ (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)token;
+ (void)didFailToRegisterForRemoteNotificationsWithError:(NSError *)error;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
#pragma clang diagnostic ignored "-Wstrict-prototypes"
+ (void)didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings;
#pragma clang diagnostic pop
/**
 * Call this method from application:didReceiveRemoteNotification:fetchCompletionHandler when Swizzling is Disabled.
 * Call the completionHandler yourself.
 */
+ (void)didReceiveRemoteNotification:(NSDictionary *)userInfo;
/**
 * Call this method from userNotificationCenter:didReceive:withCompletionHandler when Swizzling is Disabled.
 * Call the completionHandler yourself.
 */
+ (void)didReceiveNotificationResponse:(UNNotificationResponse *)response API_AVAILABLE(ios(10.0));
/**
 * Call this method from userNotificationCenter:willPresent:withCompletionHandler when Swizzling is Disabled.
 * Call the completionHandler yourself.
 */
+ (void)willPresentNotification:(UNNotification *)notification API_AVAILABLE(ios(10.0));
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
#pragma clang diagnostic ignored "-Wstrict-prototypes"
+ (void)didReceiveLocalNotification:(UILocalNotification *)localNotification;
#pragma clang diagnostic pop

/**
 * Call this to handle custom actions for local notifications.
 * Call the completionHandler yourself.
 */
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
#pragma clang diagnostic ignored "-Wstrict-prototypes"
+ (void)handleActionWithIdentifier:(NSString *)identifier
              forLocalNotification:(UILocalNotification *)notification
                 completionHandler:(void (^)(UIBackgroundFetchResult))completionHandler;
#pragma clang diagnostic pop

/**
 * Call this to handle custom actions for remote notifications.
 * Call the completionHandler yourself.
 */
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wstrict-prototypes"
+ (void)handleActionWithIdentifier:(NSString *)identifier
             forRemoteNotification:(NSDictionary *)notification
                 completionHandler:(void (^)(UIBackgroundFetchResult))completionHandler;
#pragma clang diagnostic pop

/**
 * Block to call that decides whether a notification should be displayed when it is
 * received while the app is running, and the notification is not muted.
 * Overrides the default behavior of showing an alert view with the notification message.
 */
+ (void)setShouldOpenNotificationHandler:(LeanplumShouldHandleNotificationBlock)block;

/**
 * CleverTap push notifications specific.
 * Sets whether a notification's deeplink should be opened when push notification is recevied while the app is on the foreground.
 * Default value is false.
 */
+ (void)setCleverTapOpenDeepLinksInForeground:(BOOL)openDeepLinksInForeground;

/**
 * CleverTap push notifications specific.
 * Block to call that decides how to handle a CleverTap push notification.
 * received while the app is running, and the notification is not muted.
 * The block provides the notification userInfo, a bool if the push is received or opened, and a block with the default implementation.
 * @see LeanplumHandleCleverTapNotificationBlock for details.
 */
+ (void)setHandleCleverTapNotification:(_Nullable LeanplumHandleCleverTapNotificationBlock)block;

/**
 * Sets if a Deliver event should be tracked when a Push Notification is received.
 * Default value is true - event is tracked.
 * @see PUSH_DELIVERED_EVENT_NAME for the event name
 */
+ (void)setPushDeliveryTrackingEnabled:(BOOL)enabled;

+ (void)setPushNotificationPresentationOption:(UNNotificationPresentationOptions)options API_AVAILABLE(ios(10.0));

/**
 * @{
 * Adds a responder to be executed when an event happens.
 * Similar to the methods above but uses NSInvocations instead of blocks.
 * @see onStartResponse:
 */
+ (void)addStartResponseResponder:(id)responder withSelector:(SEL)selector;
+ (void)addVariablesChangedResponder:(id)responder withSelector:(SEL)selector;
+ (void)addVariablesChangedAndNoDownloadsPendingResponder:(id)responder withSelector:(SEL)selector;
+ (void)removeStartResponseResponder:(id)responder withSelector:(SEL)selector;
+ (void)removeVariablesChangedResponder:(id)responder withSelector:(SEL)selector;
+ (void)removeVariablesChangedAndNoDownloadsPendingResponder:(id)responder withSelector:(SEL)selector;
/**@}*/

/**
 * Sets additional user attributes after the session has started.
 * Variables retrieved by start won't be targeted based on these attributes, but
 * they will count for the current session for reporting purposes.
 * Only those attributes given in the dictionary will be updated. All other
 * attributes will be preserved.
 */
+ (void)setUserAttributes:(NSDictionary *)attributes;

/**
 * Updates a user ID after session start.
 */
+ (void)setUserId:(NSString *)userId
NS_SWIFT_NAME(setUserId(_:));

/**
 * Updates a user ID after session start with a dictionary of user attributes.
 */
+ (void)setUserId:(NSString *)userId withUserAttributes:(NSDictionary *)attributes
NS_SWIFT_NAME(setUserId(_:attributes:));

/**
 * Sets the traffic source info for the current user.
 * Keys in info must be one of: publisherId, publisherName, publisherSubPublisher,
 * publisherSubSite, publisherSubCampaign, publisherSubAdGroup, publisherSubAd.
 */
+ (void)setTrafficSourceInfo:(NSDictionary *)info
NS_SWIFT_NAME(setTrafficSource(info:));

/**
 * Updates a user locale after session start.
 */
+(void)setLocale:(NSLocale *)locale
NS_SWIFT_NAME(setLocale(_:));

/**
 * @{
 * Advances to a particular state in your application. The string can be
 * any value of your choosing, and will show up in the dashboard.
 * A state is a section of your app that the user is currently in.
 * @param state The name of the state.
 */
+ (void)advanceTo:(nullable NSString *)state
NS_SWIFT_NAME(advance(state:));

/**
 * Advances to a particular state in your application. The string can be
 * any value of your choosing, and will show up in the dashboard.
 * A state is a section of your app that the user is currently in.
 * @param state The name of the state.
 * @param info Anything else you want to log with the state. For example, if the state
 * is watchVideo, info could be the video ID.
 */
+ (void)advanceTo:(nullable NSString *)state
         withInfo:(nullable NSString *)info
NS_SWIFT_NAME(advance(state:info:));

/**
 * Advances to a particular state in your application. The string can be
 * any value of your choosing, and will show up in the dashboard.
 * A state is a section of your app that the user is currently in.
 * You can specify up to 200 types of parameters per app across all events and state.
 * The parameter keys must be strings, and values either strings or numbers.
 * @param state The name of the state.
 * @param params A dictionary with custom parameters.
 */
+ (void)advanceTo:(nullable NSString *)state
   withParameters:(nullable NSDictionary<NSString *, id> *)params
NS_SWIFT_NAME(advance(state:params:));

/**
 * Advances to a particular state in your application. The string can be
 * any value of your choosing, and will show up in the dashboard.
 * A state is a section of your app that the user is currently in.
 * You can specify up to 200 types of parameters per app across all events and state.
 * The parameter keys must be strings, and values either strings or numbers.
 * @param state The name of the state. (nullable)
 * @param info Anything else you want to log with the state. For example, if the state
 * is watchVideo, info could be the video ID.
 * @param params A dictionary with custom parameters.
 */
+ (void)advanceTo:(nullable NSString *)state
         withInfo:(nullable NSString *)info
    andParameters:(nullable NSDictionary<NSString *, id> *)params
NS_SWIFT_NAME(advance(state:info:params:));

/**
 * Pauses the current state.
 * You can use this if your game has a "pause" mode. You shouldn't call it
 * when someone switches out of your app because that's done automatically.
 */
+ (void)pauseState;

/**
 * Resumes the current state.
 */
+ (void)resumeState;

/**
 * Manually track purchase event with currency code in your application. It is advised to use
 * trackInAppPurchases to automatically track IAPs.
 */
+ (void)trackPurchase:(NSString *)event
            withValue:(double)value
      andCurrencyCode:(nullable NSString *)currencyCode
        andParameters:(nullable NSDictionary<NSString *, id> *)params
NS_SWIFT_NAME(track(event:value:currencyCode:params:));


/**
 * Automatically tracks InApp purchase and does server side receipt validation.
 */
+ (void)trackInAppPurchases;

/**
 * Manually tracks InApp purchase and does server side receipt validation.
 */
+ (void)trackInAppPurchase:(SKPaymentTransaction *)transaction
NS_SWIFT_NAME(track(transaction:));
/**@}*/

/**
 * @{
 * Logs a particular event in your application. The string can be
 * any value of your choosing, and will show up in the dashboard.
 * To track a purchase, use LP_PURCHASE_EVENT.
 */
+ (void)track:(NSString *)event;

+ (void)track:(NSString *)event
    withValue:(double)value
NS_SWIFT_NAME(track(_:value:));

+ (void)track:(NSString *)event
     withInfo:(nullable NSString *)info
NS_SWIFT_NAME(track(_:info:));

+ (void)track:(NSString *)event
    withValue:(double)value
      andInfo:(nullable NSString *)info
NS_SWIFT_NAME(track(_:value:info:));

// See above for the explanation of params.
+ (void)track:(NSString *)event withParameters:(nullable NSDictionary<NSString *, id> *)params
NS_SWIFT_NAME(track(_:params:));

+ (void)track:(NSString *)event
    withValue:(double)value
andParameters:(nullable NSDictionary<NSString *, id> *)params
NS_SWIFT_NAME(track(_:value:params:));

+ (void)track:(NSString *)event
    withValue:(double)value
      andInfo:(nullable NSString *)info
andParameters:(nullable NSDictionary<NSString *, id> *)params
NS_SWIFT_NAME(track(_:value:info:params:));
/**@}*/

+ (void)trackGeofence:(LPGeofenceEventType)event
             withInfo:(nullable NSString *)info
NS_SWIFT_NAME(track(_:info:));

/**
 * @{
 * Gets the path for a particular resource. The resource can be overridden by the server.
 */
+ (NSString *)pathForResource:(NSString *)name ofType:(NSString *)extension;
+ (id)objectForKeyPath:(id)firstComponent, ... NS_REQUIRES_NIL_TERMINATION;
+ (id)objectForKeyPathComponents:(NSArray *)pathComponents;
/**@}*/


/**
 * Set variant debug info to be obtained from the server.
 */
+ (void)setVariantDebugInfoEnabled:(BOOL)variantDebugInfoEnabled;

/**
 * Gets a list of content assignments for the current user.
 */
+ (NSDictionary<NSString *, id> *)variantDebugInfo;


/**
 * Gets a list of variants that are currently active for this user.
 * Each variant is a dictionary containing an id.
 */
+ (NSArray<NSDictionary<NSString *, id> *> *)variants;

/**
 * Returns metadata for all active in-app messages.
 * Recommended only for debugging purposes and advanced use cases.
 */
+ (NSDictionary<NSString *, id> *)messageMetadata;

/**
 * Forces content to update from the server. If variables have changed, the
 * appropriate callbacks will fire. Use sparingly as if the app is updated,
 * you'll have to deal with potentially inconsistent state or user experience.
 */
+ (void)forceContentUpdate
NS_SWIFT_UNAVAILABLE("use forceContentUpdate(completion:)");

/**
 * Forces content to update from the server. If variables have changed, the
 * appropriate callbacks will fire. Use sparingly as if the app is updated,
 * you'll have to deal with potentially inconsistent state or user experience.
 * The provided callback will always fire regardless
 * of whether the variables have changed.
 */
+ (void)forceContentUpdate:(nullable LeanplumVariablesChangedBlock)block;

/**
 * Forces content to update from the server. If variables have changed, the
 * appropriate callbacks will fire. Use sparingly as if the app is updated,
 * you'll have to deal with potentially inconsistent state or user experience.
 * The provided callback has a boolean flag whether the update was successful or not. The callback fires regardless
 * of whether the variables have changed.
 */
+ (void)forceContentUpdateWithBlock:(LeanplumForceContentUpdateBlock)updateBlock;

/**
 * This should be your first statement in a unit test. This prevents
 * Leanplum from communicating with the server.
 * Deprecated. Use [Leanplum setTestModeEnabled:YES] instead.
 */
+ (void)enableTestMode
__attribute__((deprecated("Use [Leanplum setTestModeEnabled:YES] instead.")));

/**
 * Used to enable or disable test mode. Test mode prevents Leanplum from
 * communicating with the server. This is useful for unit tests.
 */
+ (void)setTestModeEnabled:(BOOL)isTestModeEnabled;

/**
 * Customize push setup. If this API should be called before [Leanplum start]. If this API is not
 * used the default push setup from the docs will be used for "Push Ask to Ask" and 
 * "Register For Push".
 */
+ (void)setPushSetup:(LeanplumPushSetupBlock)block;

/**
 * Get the push setup block.
 */
+ (nullable LeanplumPushSetupBlock)pushSetupBlock;

/**
 * Returns the app version used by Leanplum.
 */
+ (nullable NSString *)appVersion;

/**
 * Returns the deviceId in the current Leanplum session. This should only be called after
 * [Leanplum start].
 */
+ (nullable NSString *)deviceId;

/**
 * Returns the userId in the current Leanplum session. This should only be called after
 * [Leanplum start].
 */
+ (nullable NSString *)userId;

/**
 * Returns an instance to the singleton LPInbox object.
 */
+ (LPInbox *)inbox;

/**
 * Types of location accuracy. Higher value implies better accuracy.
 */
typedef NS_ENUM(NSUInteger, LPLocationAccuracyType) {
    LPLocationAccuracyIP NS_SWIFT_NAME(ip) = 0,
    LPLocationAccuracyCELL NS_SWIFT_NAME(cell) = 1,
    LPLocationAccuracyGPS NS_SWIFT_NAME(gps) = 2
} NS_SWIFT_NAME(Leanplum.LocationAccuracyType);

/**
 * Set location manually. Calls setDeviceLocationWithLatitude:longitude:type: with cell type.
 * Best if used in after calling setDeviceLocationWithLatitude:.
 */
+ (void)setDeviceLocationWithLatitude:(double)latitude
                            longitude:(double)longitude
NS_SWIFT_NAME(setDeviceLocation(latitude:longitude:));

/**
 * Set location manually. Best if used in after calling setDeviceLocationWithLatitude:.
 * Useful if you want to apply additional logic before sending in the location.
 */
+ (void)setDeviceLocationWithLatitude:(double)latitude
                            longitude:(double)longitude
                                 type:(LPLocationAccuracyType)type
NS_SWIFT_NAME(setDeviceLocation(latitude:longitude:type:));

/**
 * Set location manually. Best if used in after calling setDeviceLocationWithLatitude:.
 * If you have the CLPlacemark info: city is locality, region is administrativeArea,
 * and country is ISOcountryCode.
 */
+ (void)setDeviceLocationWithLatitude:(double)latitude
                            longitude:(double)longitude
                                 city:(nullable NSString *)city
                               region:(nullable NSString *)region
                              country:(nullable NSString *)country
                                 type:(LPLocationAccuracyType)type
NS_SWIFT_NAME(setDeviceLocation(latitude:longitude:city:region:country:type:));

/**
 * Disables collecting location automatically. Will do nothing if Leanplum-Location is not used.
 */
+ (void)disableLocationCollection;

/**
 Sets the time interval to periodically upload events to server.
 Default is 15 minutes.
 @param uploadInterval The time between uploads.
 */
+ (void)setEventsUploadInterval:(LPEventsUploadInterval)uploadInterval;

/**
 Returns the last received signed variables. If signature was not provided from server the result of this method will be nil.
 * @return @c LPSecuredVars instance containing variable's JSON and signature. If signature wasn't downloaded from server it will return nil.
 */
+ (nullable LPSecuredVars *)securedVars;

/**
 Enables system push notifications through Leanplum SDK
 */
+ (void)enablePushNotifications;

/**
 Enables provisional push notifications through Leanplum SDK
 */
+ (void)enableProvisionalPushNotifications API_AVAILABLE(ios(12.0));

/**
 * Block to call when CleverTapAPI instance is created.
 * __CleverTapSDK must be imported to use this method.__
 * Use the instance for any CleverTap work.
 *
 * @remark CleverTapSDK must be imported to use the `CleverTapInstanceCallback`.
 *
 * @param callback Null value will remove the callback.
 */
+ (void)addCleverTapInstanceCallback:(CleverTapInstanceCallback *)callback
NS_SWIFT_NAME(addCleverTapInstance(callback:));

/**
 * Removes the callback for the CleverTap instance.
 *
 * @param callback Callback to remove.
 */
+ (void)removeCleverTapInstanceCallback:(CleverTapInstanceCallback *)callback
NS_SWIFT_NAME(removeCleverTapInstance(callback:));

@end

NS_ASSUME_NONNULL_END
