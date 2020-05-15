//
//  LPNotificationsHelper.m
//  Leanplum-iOS-SDK
//
//  Created by Dejan . Krstevski on 15.05.20.
//

#import "LPNotificationsHelper.h"
#import "LPNotificationsConstants.h"
#import "LPPushNotificationsManager.h"

@implementation LPNotificationsHelper

+ (LPNotificationsHelper *)shared
{
    static LPNotificationsHelper *_sharedManager = nil;
    static dispatch_once_t notificationsHelperToken;
    dispatch_once(&notificationsHelperToken, ^{
        _sharedManager = [[self alloc] init];
    });
    return _sharedManager;
}

-(void)didReceiveNotification:(NSDictionary *)userInfo
{
    [[LPPushNotificationsManager sharedManager].handler didReceiveRemoteNotification:userInfo
                                                                          withAction:nil
                                                              fetchCompletionHandler:nil];
}

- (NSString *)messageIdFromUserInfo:(NSDictionary *)userInfo
{
    NSString *messageId = [userInfo[LP_KEY_PUSH_MESSAGE_ID] description];
    if (messageId == nil) {
        messageId = [userInfo[LP_KEY_PUSH_MUTE_IN_APP] description];
        if (messageId == nil) {
            messageId = [userInfo[LP_KEY_PUSH_NO_ACTION] description];
            if (messageId == nil) {
                messageId = [userInfo[LP_KEY_PUSH_NO_ACTION_MUTE] description];
            }
        }
    }
    return messageId;
}

@end
