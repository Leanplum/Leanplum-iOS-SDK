//
//  LPPushNotificationsHandler.h
//  Leanplum-iOS-Location
//
//  Created by Dejan . Krstevski on 5.05.20.
//

#import <Foundation/Foundation.h>
#import "Leanplum.h"

NS_ASSUME_NONNULL_BEGIN

@interface LPPushNotificationsHandler : NSObject

@property (nonatomic, strong) LeanplumShouldHandleNotificationBlock shouldHandleNotification;

- (void)didReceiveRemoteNotification:(NSDictionary *)userInfo
            withAction:(NSString *__nullable)action
              fetchCompletionHandler:(LeanplumFetchCompletionBlock)completionHandler;
- (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)token;
- (void)didFailToRegisterForRemoteNotificationsWithError:(NSError *)error;
- (void)willPresentNotification:(UNNotification *)notification
          withCompletionHandler:(void(^)(UNNotificationPresentationOptions options))completionHandler API_AVAILABLE(ios(10.0));
- (void)didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler;
- (void)handleNotification:(NSDictionary *)userInfo
       withAction:(NSString *)action
        appActive:(BOOL)active
         completionHandler:(LeanplumFetchCompletionBlock)completionHandler;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
#pragma clang diagnostic ignored "-Wstrict-prototypes"
- (void)didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings;
- (void)sendUserNotificationSettingsIfChanged:(UIUserNotificationSettings *)notificationSettings;
#pragma clang diagnostic pop

- (NSString *)messageIdFromUserInfo:(NSDictionary *)userInfo;//TODO:Dejan consider making this method private
@end

NS_ASSUME_NONNULL_END
