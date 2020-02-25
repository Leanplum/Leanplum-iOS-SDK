//
//  LPAlertMessageSnapshotTest.m
//  Leanplum-SDK_Tests
//
//  Created by Mayank Sanganeria on 2/25/20.
//  Copyright © 2020 Leanplum. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <FBSnapshotTestCase/FBSnapshotTestCase.h>

@interface LPAlertMessageSnapshotTest : FBSnapshotTestCase

@end

@implementation LPAlertMessageSnapshotTest

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
    [super setUp];
//    self.recordMode = YES;
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    UIView *view = [[UIView alloc] init];
    view.frame = CGRectMake(0, 0, 100, 100);
    view.backgroundColor = [UIColor redColor];
    FBSnapshotVerifyView(view, nil);
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
