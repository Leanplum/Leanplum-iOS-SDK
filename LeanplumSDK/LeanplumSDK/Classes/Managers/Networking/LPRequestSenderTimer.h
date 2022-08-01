//
//  LPRequestSenderTimer.h
//  Leanplum-iOS-SDK
//
//  Copyright © 2020 Leanplum. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 The enumeration represents time interval to periodically upload events to server.
 Possible values are 5, 10, or 15 minutes.
 */
typedef enum : NSUInteger {
    AT_MOST_5_MINUTES = 5,
    AT_MOST_10_MINUTES = 10,
    AT_MOST_15_MINUTES = 15
} LPEventsUploadInterval;

@interface LPRequestSenderTimer : NSObject
@property (assign) LPEventsUploadInterval timerInterval;
+ (instancetype)sharedInstance;
- (void)start;
- (void)invalidate;
@end

NS_ASSUME_NONNULL_END
