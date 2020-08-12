//
//  LPAlertMessageSnapshotTest.m
//  Leanplum-SDK_Tests
//
//  Created by Mayank Sanganeria on 2/25/20.
//  Copyright © 2020 Leanplum. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <FBSnapshotTestCase/FBSnapshotTestCase.h>
#import "Leanplum+Extensions.h"
#import "LPConfirmMessageTemplate.h"
#import "LeanplumHelper.h"


@interface LPConfirmMessageSnapshotTest : FBSnapshotTestCase

@end

@implementation LPConfirmMessageSnapshotTest

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
    LPActionContext *context = [LPActionContext actionContextWithName:LPMT_CONFIRM_NAME args:@{
        LPMT_ARG_TITLE: APP_NAME,
        LPMT_ARG_MESSAGE: LPMT_DEFAULT_CONFIRM_MESSAGE,
        LPMT_ARG_ACCEPT_TEXT: LPMT_DEFAULT_YES_BUTTON_TEXT,
        LPMT_ARG_CANCEL_TEXT: LPMT_DEFAULT_NO_BUTTON_TEXT,
    } messageId:0];

    LPConfirmMessageTemplate *template = [[LPConfirmMessageTemplate alloc] init];
    UIViewController *viewController = [template viewControllerWithContext:context];

    FBSnapshotVerifyView(viewController.view, nil);
}

@end
