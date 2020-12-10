//
//  LPRequestBatch.m
//  Leanplum-iOS-SDK
//
//  Copyright © 2020 Leanplum. All rights reserved.
//

#import "LPRequestBatch.h"
#import "LPNetworkConstants.h"

@implementation LPRequestBatch


- (instancetype)initWithRequestsToSend:(NSArray *)requestsToSend
{
    if (self = [super init])
    {
        _requestsToSend = requestsToSend;
    }
    
    return self;
}

- (int)getEventsCount
{
    return (int)self.requestsToSend.count;
}

- (BOOL)isFull
{
    return [self getEventsCount] == LP_MAX_EVENTS_PER_API_CALL;
}

- (BOOL)isEmpty
{
    return self.requestsToSend.count == 0;
}


@end
