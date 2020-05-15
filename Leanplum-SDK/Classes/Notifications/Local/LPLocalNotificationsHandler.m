//
//  LPLocalNotificationsHandler.m
//  Leanplum-iOS-SDK
//
//  Created by Dejan . Krstevski on 12.05.20.
//

#import "LPLocalNotificationsHandler.h"
#import "LeanplumInternal.h"
#import "LPNotificationsHelper.h"

@implementation LPLocalNotificationsHandler

- (void)didReceiveLocalNotification:(UILocalNotification *)localNotification
{
    NSDictionary *userInfo = [localNotification userInfo];
    
    LP_TRY
    [[LPNotificationsHelper shared] didReceiveNotification:userInfo];
    LP_END_TRY
}

@end
