#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import <Leanplum/Leanplum_WebSocket+Utils.h>
#import <Leanplum/Leanplum.h>

@interface Leanplum_WebSocketTest : XCTestCase

@end

@implementation Leanplum_WebSocketTest

- (void)testIsHandshakeSuccessfulLegacyResponse
{
    NSString *response = @"HTTP/1.1 101 Web Socket Protocol Handshake\r\n\
Upgrade: WebSocket\r\n\
Connection: Upgrade\r\n";
    XCTAssertTrue([Leanplum_WebSocket isHandshakeSuccessful:response]);
}

- (void)testIsHandshakeSuccessfulResponse
{
    NSString *response = @"HTTP/1.1 101 Switching Protocols\r\n\
WebSocket-Origin: http://dev.leanplum.com\r\n\
WebSocket-Location: ws://dev.leanplum.com/socket.io/1/websocket/y12oUiE3teSTh4S5TeSt\r\n\
Date: Wed, 31 Jan 2024 15:27:15 GMT\r\n\
Via: 1.1 google\r\n\
Upgrade: websocket\r\n\
Connection: Upgrade";
    XCTAssertTrue([Leanplum_WebSocket isHandshakeSuccessful:response]);
}

- (void)testIsHandshakeSuccessfulResponseCaseInsensitive
{
    NSString *response = @"HTTP/1.1 101 Switching Protocols\r\n\
Upgrade: WebSocket\r\n\
Connection: upgrade";
    XCTAssertTrue([Leanplum_WebSocket isHandshakeSuccessful:response]);
    
    response = @"HTTP/1.1 101 Switching Protocols\r\n\
upgrade: websocket\r\n\
connection: Upgrade";
    XCTAssertTrue([Leanplum_WebSocket isHandshakeSuccessful:response]);
}

- (void)testIsHandshakeSuccessfulInvalidStatusCode
{
    NSString *response = @"HTTP/1.1 100 Switching Protocols\r\n\
Upgrade: websocket\r\n\
Connection: Upgrade";
    XCTAssertFalse([Leanplum_WebSocket isHandshakeSuccessful:response]);
}

- (void)testIsHandshakeSuccessfulInvalidHeaders
{
    NSString *response = @"HTTP/1.1 100 Switching Protocols\r\n\
Upgrade: protocol/1\r\n\
Connection: keep-alive";
    XCTAssertFalse([Leanplum_WebSocket isHandshakeSuccessful:response]);
    
    NSString *responseInvalidConnection = @"HTTP/1.1 101 Switching Protocols\r\n\
Upgrade: websocket\r\n\
Connection: keep-alive";
    XCTAssertFalse([Leanplum_WebSocket isHandshakeSuccessful:responseInvalidConnection]);
    
    NSString *responseInvalidUpgrade = @"HTTP/1.1 101 Switching Protocols\r\n\
Upgrade: protocol/1\r\n\
Connection: Upgrade";
    XCTAssertFalse([Leanplum_WebSocket isHandshakeSuccessful:responseInvalidUpgrade]);
}

- (void)testIsHandshakeSuccessfulMissingHeaders
{
    NSString *response = @"HTTP/1.1 100 Switching Protocols\r\n\
WebSocket-Origin: http://dev.leanplum.com\r\n\
WebSocket-Location: ws://dev.leanplum.com/socket.io/1/websocket/y12oUiE3teSTh4S5TeSt\r\n\
Date: Wed, 31 Jan 2024 15:27:15 GMT\r\n\
Via: 1.1 google";
    XCTAssertFalse([Leanplum_WebSocket isHandshakeSuccessful:response]);
}

- (void)testIsHandshakeSuccessfulInvalidResponse
{
    NSString *response = @"HTTP/1.1";
    XCTAssertFalse([Leanplum_WebSocket isHandshakeSuccessful:response]);
    
    response = @"HTTP/1.1 101 Switching Protocols";
    XCTAssertFalse([Leanplum_WebSocket isHandshakeSuccessful:response]);
    
    response = @"HTTP/1.1 Switching Protocols\r\n\
WebSocket-Origin: http://dev.leanplum.com\r\n";
    XCTAssertFalse([Leanplum_WebSocket isHandshakeSuccessful:response]);
}

- (void)testIsHandshakeSuccessfulEmptyResponse
{
    NSString *response = @"";
    XCTAssertFalse([Leanplum_WebSocket isHandshakeSuccessful:response]);
}

@end
