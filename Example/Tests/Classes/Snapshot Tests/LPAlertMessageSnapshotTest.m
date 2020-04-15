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
#import "LeanplumHelper.h"

@interface LPAlertMessageSnapshotTest : FBSnapshotTestCase

@end

@implementation LPAlertMessageSnapshotTest

- (void)setUp {
    [super setUp];
    [UIView setAnimationsEnabled:NO];
    self.recordMode = recordSnapshots;
}

- (void)tearDown {
    [super tearDown];
    [LeanplumHelper dismissPresentedViewControllers];
}

- (void)testView {
    LPActionContext *context = [LPActionContext actionContextWithName:LPMT_ALERT_NAME args:@{
        LPMT_ARG_TITLE:APP_NAME,
        LPMT_ARG_MESSAGE:LPMT_DEFAULT_ALERT_MESSAGE,
        LPMT_ARG_DISMISS_TEXT:LPMT_DEFAULT_OK_BUTTON_TEXT,
    } messageId:0];

    LPAlertMessageTemplate* template = [[LPAlertMessageTemplate alloc] init];
    UIAlertController *alertViewController = [template viewControllerWith:context];

    [LPMessageTemplateUtilities presentOverVisible:alertViewController];
    
    XCTestExpectation *expects = [self expectationWithDescription:@"wait_for_load"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * 1.0), dispatch_get_main_queue(), ^{
        FBSnapshotVerifyView(alertViewController.view, nil);
        [expects fulfill];
    });
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

@end

