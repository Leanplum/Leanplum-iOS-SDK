//
//  LPNotificationsManager.h
//  Leanplum-iOS-SDK
//
//  Created by Dejan Krstevski on 15.05.20.
//  Copyright © 2020 Leanplum. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LPNotificationsManager : NSObject

+ (LPNotificationsManager *)shared;
- (NSString *)hexadecimalStringFromData:(NSData *)data;

@end

NS_ASSUME_NONNULL_END
