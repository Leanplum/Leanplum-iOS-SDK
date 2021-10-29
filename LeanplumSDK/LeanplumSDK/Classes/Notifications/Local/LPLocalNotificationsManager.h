//
//  LPLocalNotificationsManager.h
//  Leanplum-iOS-Location
//
//  Created by Dejan Krstevski on 12.05.20.
//  Copyright © 2020 Leanplum. All rights reserved.
//

#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN

@interface LPLocalNotificationsManager : NSObject

+ (LPLocalNotificationsManager *)sharedManager;
- (void)listenForLocalNotifications;
@end

NS_ASSUME_NONNULL_END
