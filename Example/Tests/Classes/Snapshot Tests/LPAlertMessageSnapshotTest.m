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

- (void)testViewController {
    LPActionContext *context = [LPActionContext actionContextWithName:LPMT_ALERT_NAME args:@{
        LPMT_ARG_TITLE:APP_NAME,
        LPMT_ARG_MESSAGE:LPMT_DEFAULT_ALERT_MESSAGE,
        LPMT_ARG_DISMISS_TEXT:LPMT_DEFAULT_OK_BUTTON_TEXT,
    } messageId:0];

    LPAlertMessageTemplate* template = [[LPAlertMessageTemplate alloc] init];
    UIViewController *viewController = [template viewControllerWithContext:context];
    FBSnapshotVerifyView(viewController.view, nil);
}

@end

