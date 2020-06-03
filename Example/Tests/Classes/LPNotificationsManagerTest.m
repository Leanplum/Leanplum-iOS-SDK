//
//  LPNotificationsManagerTest.m
//  Leanplum-SDK_Tests
//
//  Created by Dejan Krstevski on 19.05.20.
//  Copyright © 2020 Leanplum. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "LPNotificationsManager.h"
@interface LPNotificationsManagerTest : XCTestCase

@end

@implementation LPNotificationsManagerTest

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)test_messageId_from_userinfo
{
    NSDictionary *userInfo = nil;
    NSString* messageId = nil;

    userInfo = @{@"_lpm": @"messageId"};
    messageId = [[LPNotificationsManager shared] messageIdFromUserInfo:userInfo];
    XCTAssertEqual(messageId, @"messageId");

    userInfo = @{@"_lpu": @"messageId"};
    messageId = [[LPNotificationsManager shared] messageIdFromUserInfo:userInfo];
    XCTAssertEqual(messageId, @"messageId");

    userInfo = @{@"_lpn": @"messageId"};
    messageId = [[LPNotificationsManager shared] messageIdFromUserInfo:userInfo];
    XCTAssertEqual(messageId, @"messageId");

    userInfo = @{@"_lpv": @"messageId"};
    messageId = [[LPNotificationsManager shared] messageIdFromUserInfo:userInfo];
    XCTAssertEqual(messageId, @"messageId");
}

-(void)testHexadecimalStringFromData {
    NSString *testString = @"74657374537472696e67";
    NSData *data = [self hexDataFromString:testString];
    NSString *parsedString = [[LPNotificationsManager shared] hexadecimalStringFromData:data];
    XCTAssertEqualObjects(testString, parsedString);
}

-(NSMutableData*)hexDataFromString:(NSString*)string {

    NSMutableData *hexData= [[NSMutableData alloc] init];
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'};
    int i;
    for (i=0; i < [string length]/2; i++) {
        byte_chars[0] = [string characterAtIndex:i*2];
        byte_chars[1] = [string characterAtIndex:i*2+1];
        whole_byte = strtol(byte_chars, NULL, 16);
        [hexData appendBytes:&whole_byte length:1];
    }
    return hexData;
}

@end
