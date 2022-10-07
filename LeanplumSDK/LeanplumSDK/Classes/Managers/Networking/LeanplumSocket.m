//
//  LeanplumSocket.m
//  Leanplum
//
//  Created by Andrew First on 5/5/12.
//  Copyright (c) 2012 Leanplum, Inc. All rights reserved.
//
//  Licensed to the Apache Software Foundation (ASF) under one
//  or more contributor license agreements.  See the NOTICE file
//  distributed with this work for additional information
//  regarding copyright ownership.  The ASF licenses this file
//  to you under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing,
//  software distributed under the License is distributed on an
//  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
//  KIND, either express or implied.  See the License for the
//  specific language governing permissions and limitations
//  under the License.

#import "LeanplumSocket.h"
#import "LeanplumInternal.h"
#import "LPConstants.h"
#import "LPVarCache.h"
#import "LPActionTriggerManager.h"
#import "LPCountAggregator.h"
#import <Leanplum/Leanplum-Swift.h>

id<LPNetworkEngineProtocol> engine_;

@interface LeanplumSocket()

@property (nonatomic, strong) LPCountAggregator *countAggregator;

@end

@implementation LeanplumSocket

static LeanplumSocket *leanplum_sharedSocket = nil;
static dispatch_once_t leanplum_onceToken;

+ (LeanplumSocket *)sharedSocket
{
    dispatch_once(&leanplum_onceToken, ^{
        leanplum_sharedSocket = [[self alloc] init];
    });
    return leanplum_sharedSocket;
}

+ (id<LPNetworkEngineProtocol>)engine
{
    if (engine_ == nil) {
        NSString *userAgentString = [NSString stringWithFormat:@"%@/%@(%@; %@; %@)",
                                     NSBundle.mainBundle.infoDictionary[(NSString *)
                                                                        kCFBundleNameKey],
                                     NSBundle.mainBundle.infoDictionary[(NSString *)
                                                                        kCFBundleVersionKey],
                                     [ApiConfig shared].appId,
                                     LEANPLUM_CLIENT,
                                     LEANPLUM_SDK_VERSION];
        engine_ = [LPNetworkFactory
                   engineWithCustomHeaderFields:@{@"User-Agent": userAgentString}];
    }
    return engine_;
}

- (id)init
{
    self = [super init];
    if (self) {
        [self initWithDelegate];
    }
    return self;
}

- (void)initWithDelegate
{
    if (![LPConstantsState sharedState].isTestMode) {
        if (_socketIO == nil) {
            _socketIO = [[Leanplum_SocketIO alloc] initWithDelegate:self];
        }
        _connected = NO;
        _authSent = NO;
    }
    _countAggregator = [LPCountAggregator sharedAggregator];
}

- (void)connectToAppId:(NSString *)appId deviceId:(NSString *)deviceId
{
    if (!_socketIO) {
        return;
    }
    _appId = appId;
    _deviceId = deviceId;
    [self connect];
    _reconnectTimer = [NSTimer scheduledTimerWithTimeInterval:5 target:self
                                                     selector:@selector(reconnect)
                                                     userInfo:nil repeats:YES];
    
    [self.countAggregator incrementCount:@"connect_to_app_id"];
}

- (void)connect
{
    long port = [ApiConfig shared].socketPort;
    [_socketIO connectWithEngine:[LeanplumSocket engine]
                        withHost:[ApiConfig shared].socketHost
                          onPort:port
                secureConnection:port == 443];
}

- (void)reconnect
{
    if (!_connected) {
        [self connect];
    }
}

- (void)connectToNewSocket
{
    if (_connected || [_socketIO isConnecting]) {
        [_socketIO disconnect];
        _socketIO = nil;
        [self initWithDelegate];
        [self connect];
    }
}

- (void)socketIODidConnect:(Leanplum_SocketIO *)socket
{
    if (!_authSent) {
        LPLog(LPInfo, @"Connected to development server");
        NSDictionary *dict = @{
            LP_PARAM_APP_ID: _appId,
            LP_PARAM_DEVICE_ID: _deviceId
        };
        [_socketIO sendEvent:@"auth" withData:dict];
        _authSent = YES;
        _connected = YES;
    }
}

- (void)socketIODidDisconnect:(Leanplum_SocketIO *)socketIO
{
    LPLog(LPInfo, @"Disconnected from development server");
    _connected = NO;
    _authSent = NO;
}

- (void)socketIOHandshakeFailed:(Leanplum_SocketIO *)socket
{
    LPLog(LPInfo, @"Handshake with development server failed");
    _connected = NO;
    _authSent = NO;
}

- (void)socketIO:(Leanplum_SocketIO *)socketIO didReceiveEvent:(Leanplum_SocketIOPacket *)packet
{
    LP_TRY
    if ([packet.name isEqualToString:@"updateVars"]) {
        // Refresh variables.
        [Leanplum forceContentUpdate];
    } else if ([packet.name isEqualToString:@"trigger"]) {
        // Trigger a custom action.
        NSDictionary *payload = [packet dataAsJSON][@"args"][0];
        id action = payload[LP_PARAM_ACTION];
        if (action && [action isKindOfClass:[NSDictionary class]]) {
            NSString *messageId = [payload[LP_PARAM_MESSAGE_ID] description];
            BOOL isRooted = [payload[@"isRooted"] boolValue];
            NSString *actionType = action[LP_VALUE_ACTION_ARG];
            
            NSDictionary *defaultArgs = [[[LPActionManager shared] definitionWithName:action[LP_VALUE_ACTION_ARG]] values];
            action = [ContentMerger mergeWithVars:defaultArgs diff:action];
            
            LPActionContext *context = [LPActionContext actionContextWithName:actionType
                                                                         args:action
                                                                    messageId:messageId];
            [context setIsPreview:YES];
            context.preventRealtimeUpdating = YES;
            [context setIsRooted:isRooted];
            [context maybeDownloadFiles];
            ActionsTrigger *trigger = [[ActionsTrigger alloc] initWithEventName:@"Preview"
                                                                      condition:nil
                                                               contextualValues:nil];
            [[LPActionManager shared] triggerWithContexts:@[context] priority:PriorityHigh trigger:trigger];
        }

    } else if ([packet.name isEqualToString:@"getVariables"]) {
        BOOL sentValues = [[LPVarCache sharedCache] sendVariablesIfChanged];
        [[LPVarCache sharedCache] maybeUploadNewFiles];
        [self sendEvent:@"getContentResponse" withData:@{@"updated": @(sentValues)}];

    } else if ([packet.name isEqualToString:@"getActions"]) {
        BOOL sentValues = [[LPVarCache sharedCache] sendActionsIfChanged];
        [[LPVarCache sharedCache] maybeUploadNewFiles];
        [self sendEvent:@"getContentResponse" withData:@{@"updated": @(sentValues)}];

    } else if ([packet.name isEqualToString:@"registerDevice"]) {
        NSDictionary *packetData = packet.dataAsJSON[@"args"][0];
        NSString *email = packetData[@"email"];
        [Leanplum onHasStartedAndRegisteredAsDeveloper];
        [UIAlert showWithTitle:@"Leanplum"
                       message:[NSString stringWithFormat:@"Your device is registered to %@.", email]
             cancelButtonTitle:NSLocalizedString(@"OK", nil)
             otherButtonTitles:@[]
                   actionBlock:nil];
    } else if ([packet.name isEqualToString:@"applyVars"]) {
        NSDictionary *packetData = packet.dataAsJSON[@"args"][0];
        [[LPVarCache sharedCache] applyVariableDiffs:packetData
                                            messages:nil
                                            variants:nil
                                           localCaps:nil
                                             regions:nil
                                    variantDebugInfo:nil
                                            varsJson:nil
                                       varsSignature:nil];
    }
    LP_END_TRY
}

- (void) sendEvent:(NSString *)eventName withData:(NSDictionary *)data
{
    [_socketIO sendEvent:eventName withData:data];
    
    [self.countAggregator incrementCount:@"send_event_socket"];
}

@end
