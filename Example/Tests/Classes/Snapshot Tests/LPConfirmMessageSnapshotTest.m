//
//  LPAlertMessageSnapshotTest.m
//  Leanplum-SDK_Tests
//
//  Created by Mayank Sanganeria on 2/25/20.
//  Copyright © 2020 Leanplum. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <FBSnapshotTestCase/FBSnapshotTestCase.h>
#import <Leanplum/LPActionContext.h>
#import <Leanplum/LPMessageTemplates.h>
#import <Leanplum/LPMessageTemplateConstants.h>
#import "Leanplum+Extensions.h"
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

- (void)testView {
    LPActionContext *context = [LPActionContext actionContextWithName:LPMT_CONFIRM_NAME args:@{
        LPMT_ARG_TITLE: APP_NAME,
        LPMT_ARG_MESSAGE: LPMT_DEFAULT_CONFIRM_MESSAGE,
        LPMT_ARG_ACCEPT_TEXT: LPMT_DEFAULT_YES_BUTTON_TEXT,
        LPMT_ARG_CANCEL_TEXT: LPMT_DEFAULT_NO_BUTTON_TEXT,
    } messageId:0];
    
    UIAlertController *alertViewController = [UIAlertController alertControllerWithTitle:NSLocalizedString([context stringNamed:LPMT_ARG_TITLE], nil)
                                                                                 message:NSLocalizedString([context stringNamed:LPMT_ARG_MESSAGE], nil)
                                                                          preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *cancel = [UIAlertAction actionWithTitle:NSLocalizedString([context stringNamed:LPMT_ARG_CANCEL_TEXT], nil)
                                                     style:UIAlertActionStyleCancel
                                                   handler:^(UIAlertAction *action) {
        [context runActionNamed:LPMT_ARG_CANCEL_ACTION];
    }];
    [alertViewController addAction:cancel];
    UIAlertAction *accept = [UIAlertAction actionWithTitle:NSLocalizedString([context stringNamed:LPMT_ARG_ACCEPT_TEXT], nil)
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction *action) {
        [context runTrackedActionNamed:LPMT_ARG_ACCEPT_ACTION];
    }];
    [alertViewController addAction:accept];

    [LPMessageTemplateUtilities presentOverVisible:alertViewController];
    XCTestExpectation *expects = [self expectationWithDescription:@"wait_for_load"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * 1.0), dispatch_get_main_queue(), ^{
        FBSnapshotVerifyView(alertViewController.view, nil);
        [expects fulfill];
    });
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

@end
