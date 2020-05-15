//
//  LPLocalNotificationsHandler.m
//  Leanplum-iOS-SDK
//
//  Created by Dejan . Krstevski on 12.05.20.
//

#import "LPLocalNotificationsHandler.h"
#import "LeanplumInternal.h"
@implementation LPLocalNotificationsHandler

- (void)didReceiveLocalNotification:(UILocalNotification *)localNotification
{
    NSDictionary *userInfo = [localNotification userInfo];
    
    LP_TRY
    [[LPPushNotificationsManager sharedManager].handler didReceiveRemoteNotification:userInfo
                            withAction:nil
                fetchCompletionHandler:nil];//TODO:Dejan fix warning
    LP_END_TRY
}

@end
