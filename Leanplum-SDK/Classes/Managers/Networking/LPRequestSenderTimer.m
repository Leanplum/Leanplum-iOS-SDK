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

+ (instancetype)sharedInstance {
    static LPRequestSenderTimer *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] init];
    });
    return sharedManager;
}

- (instancetype)init
{
    if (self = [super init])
    {
        _timerInterval = AT_MOST_15_MINUTES;
    }
    
    return self;
}

- (void)start
{
    NSTimeInterval heartbeatInterval = self.timerInterval * 60;
    // Heartbeat.
    [LPTimerBlocks scheduledTimerWithTimeInterval:heartbeatInterval block:^() {
        RETURN_IF_NOOP;
        LP_TRY
        if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive) {
            LPRequest *request = [[LPRequestFactory heartbeatWithParams:nil] andRequestType:Immediate];
            [[LPRequestSender sharedInstance] send:request];

        }
        LP_END_TRY
    } repeats:YES];
}

@end
