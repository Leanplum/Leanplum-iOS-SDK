//
//  LeanplumSocket.h
//  Leanplum
//
//  Copyright (c) 2018 Leanplum, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Leanplum_SocketIO.h"

@interface LeanplumSocket : NSObject <Leanplum_SocketIODelegate> {
@private
    Leanplum_SocketIO *_socketIO;
    NSString *_appId;
    NSString *_deviceId;
    BOOL _authSent;
    NSTimer *_reconnectTimer;
}
@property (readonly) BOOL connected;

+ (LeanplumSocket *)sharedSocket;

- (void)connectToAppId:(NSString *)appId deviceId:(NSString *)deviceId;
- (void)sendEvent:(NSString *)eventName withData:(NSDictionary *)data;

@end
