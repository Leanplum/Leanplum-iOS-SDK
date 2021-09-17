//
//  LPLocalNotificationsHandler.h
//  Leanplum-iOS-SDK
//
//  Created by Dejan Krstevski on 12.05.20.
//  Copyright © 2020 Leanplum. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface LPLocalNotificationsHandler : NSObject

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
- (void)didReceiveLocalNotification:(UILocalNotification *)localNotification;
#pragma clang diagnostic pop

@end

NS_ASSUME_NONNULL_END
