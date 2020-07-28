//
//  LPAlertMessageSnapshotTest.m
//  Leanplum-SDK_Tests
//
//  Created by Mayank Sanganeria on 2/25/20.
//  Copyright © 2020 Leanplum. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <FBSnapshotTestCase/FBSnapshotTestCase.h>
#import <OCMock.h>
#import "Leanplum+Extensions.h"
#import "LPInterstitialMessageTemplate.h"
#import "LeanplumHelper.h"

@interface LPInterstitialMessageSnapshotTest : FBSnapshotTestCase

@end

@implementation LPInterstitialMessageSnapshotTest

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
    LPActionContext *context = [LPActionContext actionContextWithName:LPMT_INTERSTITIAL_NAME args:@{
        LPMT_ARG_TITLE_TEXT:APP_NAME,
        LPMT_ARG_TITLE_COLOR:[UIColor blackColor],
        LPMT_ARG_MESSAGE_TEXT:LPMT_DEFAULT_INTERSTITIAL_MESSAGE,
        LPMT_ARG_MESSAGE_COLOR:[UIColor blackColor],
        LPMT_ARG_BACKGROUND_COLOR:[UIColor whiteColor],
        LPMT_ARG_ACCEPT_BUTTON_TEXT:LPMT_DEFAULT_OK_BUTTON_TEXT,
        LPMT_ARG_ACCEPT_BUTTON_BACKGROUND_COLOR:[UIColor whiteColor],
        LPMT_ARG_ACCEPT_BUTTON_TEXT_COLOR:[UIColor blackColor],
    } messageId:0];
    id contextMock = OCMPartialMock(context);
    OCMStub([contextMock stringNamed:LPMT_ARG_TITLE_TEXT]).andReturn(APP_NAME);
    OCMStub([contextMock colorNamed:LPMT_ARG_TITLE_COLOR]).andReturn([UIColor blackColor]);
    OCMStub([contextMock stringNamed:LPMT_ARG_MESSAGE_TEXT]).andReturn(LPMT_DEFAULT_INTERSTITIAL_MESSAGE);
    OCMStub([contextMock colorNamed:LPMT_ARG_MESSAGE_COLOR]).andReturn([UIColor blackColor]);
    OCMStub([contextMock colorNamed:LPMT_ARG_BACKGROUND_COLOR]).andReturn([UIColor whiteColor]);
    OCMStub([contextMock stringNamed:LPMT_ARG_ACCEPT_BUTTON_TEXT]).andReturn(LPMT_DEFAULT_OK_BUTTON_TEXT);
    OCMStub([contextMock colorNamed:LPMT_ARG_ACCEPT_BUTTON_BACKGROUND_COLOR]).andReturn([UIColor whiteColor]);
    OCMStub([contextMock colorNamed:LPMT_ARG_ACCEPT_BUTTON_TEXT_COLOR]).andReturn([UIColor blackColor]);
    
    LPInterstitialMessageTemplate *template = [[LPInterstitialMessageTemplate alloc] init];
    UIViewController *viewController = [template viewControllerWithContext:context];

    FBSnapshotVerifyView(viewController.view, nil);
}

@end
