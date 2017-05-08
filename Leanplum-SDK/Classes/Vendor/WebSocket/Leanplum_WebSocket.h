//
//  WebSocket.h
//  Zimt
//
//  Created by Esad Hajdarevic on 2/14/10.
//  Copyright 2010 OpenResearch Software Development OG. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Leanplum_AsyncSocket;
@class Leanplum_WebSocket;

@protocol Leanplum_WebSocketDelegate<NSObject>
@optional
- (void)webSocket:(Leanplum_WebSocket*)webSocket didFailWithError:(NSError*)error;
- (void)webSocketDidOpen:(Leanplum_WebSocket*)webSocket;
- (void)webSocketDidClose:(Leanplum_WebSocket*)webSocket;
- (void)webSocket:(Leanplum_WebSocket*)webSocket didReceiveMessage:(NSString*)message;
- (void)webSocketDidSendMessage:(Leanplum_WebSocket*)webSocket;
@end

@interface Leanplum_WebSocket : NSObject {
    id<Leanplum_WebSocketDelegate> __unsafe_unretained delegate;
    NSURL* url;
    Leanplum_AsyncSocket* socket;
    BOOL connected;
    NSString* origin;

    NSArray* runLoopModes;
}

@property(nonatomic,assign) id<Leanplum_WebSocketDelegate> delegate;
@property(nonatomic,readonly) NSURL* url;
@property(nonatomic,retain) NSString* origin;
@property(nonatomic,readonly) BOOL connected;
@property(nonatomic,retain) NSArray* runLoopModes;

+ (id)webSocketWithURLString:(NSString*)urlString delegate:(id<Leanplum_WebSocketDelegate>)delegate;
- (id)initWithURLString:(NSString*)urlString delegate:(id<Leanplum_WebSocketDelegate>)delegate;

- (void)open;
- (void)close;
- (void)send:(NSString*)message;

@end

enum {
    WebSocketErrorConnectionFailed = 1,
    WebSocketErrorHandshakeFailed = 2
};

extern NSString *const Leanplum_WebSocketException;
extern NSString* const Leanplum_WebSocketErrorDomain;
