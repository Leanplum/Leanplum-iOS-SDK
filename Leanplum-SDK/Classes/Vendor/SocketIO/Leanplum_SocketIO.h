//
//  SocketIO.h
//  v.01
//
//  based on 
//  socketio-cocoa https://github.com/fpotter/socketio-cocoa
//  by Fred Potter <fpotter@pieceable.com>
//
//  using
//  https://github.com/erichocean/cocoa-websocket
//  http://regexkit.sourceforge.net/RegexKitLite/
//  https://github.com/stig/json-framework/
//  http://allseeing-i.com/ASIHTTPRequest/
//
//  reusing some parts of
//  /socket.io/socket.io.js
//
//  Created by Philipp Kyeck http://beta_interactive.de
//
//  Modified by Ruben Nine http://leftbee.net in order to add SSL support
//

#import <Foundation/Foundation.h>

@class Leanplum_WebSocket;
@class Leanplum_SocketIO;
@class Leanplum_SocketIOPacket;
@class Leanplum_MKNetworkOperation;
@class Leanplum_MKNetworkEngine;
@protocol LPNetworkEngineProtocol;
@protocol LPNetworkOperationProtocol;

@protocol Leanplum_SocketIODelegate <NSObject>
@optional
- (void) socketIODidConnect:(Leanplum_SocketIO *)socket;
- (void) socketIODidDisconnect:(Leanplum_SocketIO *)socket;
- (void) socketIO:(Leanplum_SocketIO *)socket didReceiveMessage:(Leanplum_SocketIOPacket *)packet;
- (void) socketIO:(Leanplum_SocketIO *)socket didReceiveJSON:(Leanplum_SocketIOPacket *)packet;
- (void) socketIO:(Leanplum_SocketIO *)socket didReceiveEvent:(Leanplum_SocketIOPacket *)packet;
- (void) socketIO:(Leanplum_SocketIO *)socket didSendMessage:(Leanplum_SocketIOPacket *)packet;
- (void) socketIOHandshakeFailed:(Leanplum_SocketIO *)socket;
@end

@interface Leanplum_SocketIO : NSObject 
{
@private
    NSString *_host;
    NSInteger _port;
    NSString *_sid;
    
    id<Leanplum_SocketIODelegate> _delegate;
    
    Leanplum_WebSocket *_webSocket;
    
    BOOL _isConnected;
    BOOL _isConnecting;
    BOOL _useTLS;
    
    // heartbeat
    NSTimeInterval _heartbeatTimeout;
    NSTimer *_timeout;
    
    NSMutableArray *_queue;
    
    // acknowledge
    NSMutableDictionary *_acks;
    NSInteger _ackCount;
}

- (id) initWithDelegate:(id<Leanplum_SocketIODelegate>)delegate;
- (void) connectWithEngine:(id<LPNetworkEngineProtocol>)engine withHost:(NSString*)host onPort:(NSInteger)port;
- (void) connectWithEngine:(id<LPNetworkEngineProtocol>)engine withHost:(NSString*)host onPort:(NSInteger)port secureConnection:(BOOL)useTLS;
- (void) disconnect;

- (void) sendMessage:(NSString *)data;
- (void) sendMessage:(NSString *)data withAcknowledge:(SEL)function;
- (void) sendJSON:(NSDictionary *)data;
- (void) sendJSON:(NSDictionary *)data withAcknowledge:(SEL)function;
- (void) sendEvent:(NSString *)eventName withData:(NSDictionary *)data;
- (void) sendEvent:(NSString *)eventName withData:(NSDictionary *)data andAcknowledge:(SEL)function;
- (void) sendAcknowledgement:(NSString*)pId withArgs:(NSArray *)data;

- (void) requestFinished:(id<LPNetworkOperationProtocol>)op;
- (void) requestFailed:(NSError *)error;

+ (NSArray *) arrayOfCaptureComponentsOfString:(NSString *)data matchedBy:(NSRegularExpression *)regExpression;
+ (NSArray *) arrayOfCaptureComponentsOfString:(NSString *)data matchedByRegex:(NSString *)regeX;

@end


@interface Leanplum_SocketIOPacket : NSObject
{
    NSString *type;
    NSString *pId;
    NSString *ack;
    NSString *name;
    NSString *data;
    NSArray *args;
    NSString *endpoint;
    
@private
    NSArray *_types;
}

@property (nonatomic, copy) NSString *type;
@property (nonatomic, copy) NSString *pId;
@property (nonatomic, copy) NSString *ack;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *data;
@property (nonatomic, copy) NSString *endpoint;
@property (nonatomic, copy) NSArray *args;

- (id) initWithType:(NSString *)packetType;
- (id) initWithTypeIndex:(int)index;
- (id) dataAsJSON;
- (NSNumber *) typeAsNumber;
- (NSString *) typeForIndex:(int)index;

@end
