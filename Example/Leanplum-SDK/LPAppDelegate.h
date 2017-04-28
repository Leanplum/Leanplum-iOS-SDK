//
//  LPAppDelegate.h
//  Leanplum-SDK
//
//  Created by Ben Marten on 08/29/2016.
//  Copyright (c) 2016 Ben Marten. All rights reserved.
//

@import UIKit;
#if __IPHONE_OS_VERSION_MIN_REQUIRED >= 100000
@import UserNotifications;

@interface LPAppDelegate : UIResponder <UIApplicationDelegate, UNUserNotificationCenterDelegate>
#else
@interface LPAppDelegate : UIResponder <UIApplicationDelegate>
#endif

@property (strong, nonatomic) UIWindow *window;

@end
