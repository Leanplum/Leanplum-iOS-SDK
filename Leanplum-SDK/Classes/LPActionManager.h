//
//  LPActionManager.h
//  Leanplum
//
//  Copyright (c) 2018 Leanplum, Inc. All rights reserved.
//

#import "Leanplum.h"

#import <Foundation/Foundation.h>
#import "LPContextualValues.h"
#if LP_NOT_TV
#import <UserNotifications/UserNotifications.h>
#endif

struct LeanplumMessageMatchResult {
    BOOL matchedTrigger;
    BOOL matchedUnlessTrigger;
    BOOL matchedLimit;
    BOOL matchedActivePeriod;
};
typedef struct LeanplumMessageMatchResult LeanplumMessageMatchResult;

LeanplumMessageMatchResult LeanplumMessageMatchResultMake(BOOL matchedTrigger, BOOL matchedUnlessTrigger, BOOL matchedLimit, BOOL matchedActivePeriod);

typedef enum {
    kLeanplumActionFilterForeground = 0b1,
    kLeanplumActionFilterBackground = 0b10,
    kLeanplumActionFilterAll = 0b11
} LeanplumActionFilter;

#define  LP_PUSH_NOTIFICATION_ACTION @"__Push Notification"
#define  LP_HELD_BACK_ACTION @"__held_back"

@interface LPActionManager : NSObject {
  @private
    NSMutableDictionary *_messageImpressionOccurrences;
    NSMutableDictionary *_messageTriggerOccurrences;
    NSMutableDictionary *_sessionOccurrences;
    NSString *notificationHandled;
    NSDate *notificationHandledTime;
    LeanplumShouldHandleNotificationBlock shouldHandleNotification;
    NSString *displayedTracked;
    NSDate *displayedTrackedTime;

  @package
    BOOL swizzledApplicationDidRegisterRemoteNotifications;
    BOOL swizzledApplicationDidRegisterUserNotificationSettings;
    BOOL swizzledApplicationDidFailToRegisterForRemoteNotificationsWithError;
    BOOL swizzledApplicationDidReceiveRemoteNotification;
    BOOL swizzledApplicationDidReceiveRemoteNotificationWithCompletionHandler;
    BOOL swizzledApplicationDidReceiveLocalNotification;
    BOOL swizzledUserNotificationCenterDidReceiveNotificationResponseWithCompletionHandler;
}

+ (LPActionManager*) sharedManager;

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000 && LP_NOT_TV
- (void)sendUserNotificationSettingsIfChanged:(UIUserNotificationSettings *)notificationSettings;
#endif

+ (void)getForegroundRegionNames:(NSMutableSet **)foregroundRegionNames
        andBackgroundRegionNames:(NSMutableSet **)backgroundRegionNames;

- (void)setShouldHandleNotification:(LeanplumShouldHandleNotificationBlock)block;

- (void)didReceiveRemoteNotification:(NSDictionary *)userInfo
                          withAction:(NSString *)action
              fetchCompletionHandler:(LeanplumFetchCompletionBlock)completionHandler;

- (LeanplumMessageMatchResult)shouldShowMessage:(NSString *)messageId
                                     withConfig:(NSDictionary *)messageConfig
                                           when:(NSString *)when
                                  withEventName:(NSString *)eventName
                               contextualValues:(LPContextualValues *)contextualValues;

- (void)recordMessageTrigger:(NSString *)messageId;
- (void)recordMessageImpression:(NSString *)messageId;
- (void)recordHeldBackImpression:(NSString *)messageId
               originalMessageId:(NSString *)originalMessageId;

- (void)muteFutureMessagesOfKind:(NSString *)messageId;

#pragma mark - Leanplum Tests
+ (void)reset;

@end
