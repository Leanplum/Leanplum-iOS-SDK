//
//  LPLocalNotificationsManager.h
//  Leanplum-iOS-Location
//
//  Created by Dejan . Krstevski on 12.05.20.
//

#import <Foundation/Foundation.h>
#import "LPLocalNotificationsHandler.h"
NS_ASSUME_NONNULL_BEGIN

@interface LPLocalNotificationsManager : NSObject
@property (nonatomic, strong) LPLocalNotificationsHandler* handler;

+ (LPLocalNotificationsManager *)sharedManager;
- (void)listenForLocalNotifications;
@end

NS_ASSUME_NONNULL_END
