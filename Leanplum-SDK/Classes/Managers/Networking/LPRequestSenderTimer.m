//
//  LPRequestSenderTimer.m
//  Leanplum-iOS-SDK
//
//  Copyright © 2020 Leanplum. All rights reserved.
//

#import "LPRequestSenderTimer.h"
#import "NSTimer+Blocks.h"
#import "LPConstants.h"
#import "LPRequest.h"
#import "LPRequestFactory.h"
#import "LPRequestSender.h"

@implementation LPRequestSenderTimer


+ (void)start
{
    // Heartbeat.
    [LPTimerBlocks scheduledTimerWithTimeInterval:HEARTBEAT_INTERVAL block:^() {
        RETURN_IF_NOOP;
        LP_TRY
        if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive) {
            LPRequest *request = [LPRequestFactory heartbeatWithParams:nil];
            request.requestType = Immediate;
            [[LPRequestSender sharedInstance] send:request];//TODO: Dejan check sendIfDelayed

        }
        LP_END_TRY
    } repeats:YES];
}

@end
