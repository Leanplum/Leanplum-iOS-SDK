//
//  LPNetworkOperationTest.m
//  Leanplum-SDK_Tests
//
//  Created by Mayank Sanganeria on 4/16/20.
//  Copyright © 2020 Leanplum. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <Leanplum/LPNetworkOperation.h>

@interface LPNetworkOperation(Test)
- (NSString *)urlEncodedString:(NSString *)string;
@end

@interface LPNetworkOperationTest : XCTestCase

@end

@implementation LPNetworkOperationTest

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testUrlEncodedString {
    LPNetworkOperation *operation = [[LPNetworkOperation alloc] init];
    NSString *url = @"http://www.leanplum.com";
    NSString *encodedUrl = [operation urlEncodedString:url];
    XCTAssert([encodedUrl isEqualToString:@"http%3A%2F%2Fwww.leanplum.com"]);
}

@end
