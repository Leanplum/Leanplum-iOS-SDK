//
//  LPLocalNotificationsHandler.m
//  Leanplum-iOS-SDK
//
//  Created by Dejan Krstevski on 12.05.20.
//  Copyright © 2020 Leanplum. All rights reserved.
//

#import "LPLocalNotificationsHandler.h"
#import "LeanplumInternal.h"
#import "LPNotificationsManager.h"

@implementation LPLocalNotificationsHandler
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
- (void)didReceiveLocalNotification:(UILocalNotification *)localNotification
{
    NSDictionary *userInfo = [localNotification userInfo];
    
    LP_TRY
    [[LPNotificationsManager shared] handleLocalNotification:userInfo];
    LP_END_TRY
}
#pragma clang diagnostic pop

@end
