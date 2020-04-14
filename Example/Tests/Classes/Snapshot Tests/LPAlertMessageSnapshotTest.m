//
//  LPAlertMessageSnapshotTest.m
//  Leanplum-SDK_Tests
//
//  Created by Mayank Sanganeria on 2/25/20.
//  Copyright © 2020 Leanplum. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <FBSnapshotTestCase/FBSnapshotTestCase.h>
#import <Leanplum/LPAlertMessageTemplate.h>
#import "Leanplum+Extensions.h"

@interface LPAlertMessageSnapshotTest : FBSnapshotTestCase

@end

@implementation LPAlertMessageSnapshotTest

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
    [super setUp];
    self.recordMode = recordSnapshots;
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testView {
    LPActionContext *context = [LPActionContext actionContextWithName:LPMT_ALERT_NAME args:@{
        LPMT_ARG_TITLE:APP_NAME,
        LPMT_ARG_MESSAGE:LPMT_DEFAULT_ALERT_MESSAGE,
        LPMT_ARG_DISMISS_TEXT:LPMT_DEFAULT_OK_BUTTON_TEXT,
    } messageId:0];
    
    [UIView performWithoutAnimation:^{
        NSInvocation *invocation = [[LPInternalState sharedState].actionResponders objectForKey:context.actionName];
        [invocation setArgument:(void *)&context atIndex:2];
        [invocation invoke];
    }];
    
    XCTestExpectation *expects = [self expectationWithDescription:@"wait_for_load"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * 1.0), dispatch_get_main_queue(), ^{
        UIViewController *topViewController = [LPMessageTemplateUtilities visibleViewController];
        
        FBSnapshotVerifyView(topViewController.view, nil);
        [topViewController dismissViewControllerAnimated:NO completion:^{
            [expects fulfill];
        }];
    });
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

@end

