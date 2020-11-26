//
//  LPRequestBatchFactory.m
//  Leanplum-iOS-SDK
//
//  Copyright © 2020 Leanplum. All rights reserved.
//

#import "LPRequestBatchFactory.h"
#import "LPEventDataManager.h"
#import "LPNetworkConstants.h"

@implementation LPRequestBatchFactory

+ (LPRequestBatch *)createNextBatch
{
    NSArray *requests = [LPEventDataManager eventsWithLimit:LP_MAX_EVENTS_PER_API_CALL];
    return [[LPRequestBatch alloc] initWithRequestsToSend:requests];
}

+ (void)deleteFinishedBatch:(LPRequestBatch *)batch
{
    int eventsCount = [batch getEventsCount];
    if (eventsCount == 0) {
        return;;
    }
    [LPEventDataManager deleteEventsWithLimit:eventsCount];
}

@end
