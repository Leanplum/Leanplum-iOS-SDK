//
//  LPRequestBatch.h
//  Leanplum-iOS-SDK
//
//  Copyright © 2020 Leanplum. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LPRequestBatch : NSObject

@property (nonatomic, retain) NSArray *requestsToSend;

- (instancetype)initWithRequestsToSend:(NSArray *)requestsToSend;
- (int)getEventsCount;
- (BOOL)isFull;
- (BOOL)isEmpty;

@end

NS_ASSUME_NONNULL_END
