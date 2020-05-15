//
//  LPNotificationsHelper.h
//  Leanplum-iOS-SDK
//
//  Created by Dejan . Krstevski on 15.05.20.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LPNotificationsHelper : NSObject

+ (LPNotificationsHelper *)shared;
- (void)didReceiveNotification:(NSDictionary *)userInfo;
- (NSString *)messageIdFromUserInfo:(NSDictionary *)userInfo;

@end

NS_ASSUME_NONNULL_END
