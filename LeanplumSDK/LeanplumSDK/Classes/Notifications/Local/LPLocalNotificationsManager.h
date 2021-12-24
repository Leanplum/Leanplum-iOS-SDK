//
//  LPLocalNotificationsManager.h
//  Leanplum-iOS-Location
//
//  Created by Dejan Krstevski on 12.05.20.
//  Copyright © 2020 Leanplum. All rights reserved.
//

#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN
@class LPActionContext;

@interface LPLocalNotificationsManager : NSObject

+ (LPLocalNotificationsManager *)sharedManager;
- (void)scheduleLocalNotification:(LPActionContext *)context;
- (void)cancelLocalNotification:(NSString *)context;
@end

NS_ASSUME_NONNULL_END
