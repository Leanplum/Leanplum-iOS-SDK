//
//  LPAlertMessageSnapshotTest.m
//  Leanplum-SDK_Tests
//
//  Created by Mayank Sanganeria on 2/25/20.
//  Copyright © 2020 Leanplum. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <FBSnapshotTestCase/FBSnapshotTestCase.h>
#import <Leanplum/LPWebInterstitialMessageTemplate.h>
#import <OCMock.h>
#import "Leanplum+Extensions.h"
#import "LeanplumHelper.h"

@interface LPWebInterstitialMessageSnapshotTest : FBSnapshotTestCase <WKNavigationDelegate>

@end

@implementation LPWebInterstitialMessageSnapshotTest

- (void)setUp {
    [super setUp];
    [UIView setAnimationsEnabled:NO];
    self.recordMode = recordSnapshots;
}

- (void)tearDown {
    [super tearDown];
    [LeanplumHelper dismissPresentedViewControllers];
}

// commenting out until we can get this to run on CI
//- (void)testViewController {
//    LPActionContext *context = [LPActionContext actionContextWithName:LPMT_WEB_INTERSTITIAL_NAME args:@{
//        LPMT_ARG_URL:LPMT_DEFAULT_URL,
//        LPMT_ARG_URL_CLOSE:LPMT_DEFAULT_CLOSE_URL,
//        LPMT_HAS_DISMISS_BUTTON:@(LPMT_DEFAULT_HAS_DISMISS_BUTTON),
//    } messageId:0];
//    
//    id contextMock = OCMPartialMock(context);
//    OCMStub([contextMock stringNamed:LPMT_ARG_TITLE_TEXT]).andReturn(LPMT_DEFAULT_URL);
//    OCMStub([contextMock stringNamed:LPMT_ARG_MESSAGE_TEXT]).andReturn(LPMT_DEFAULT_CLOSE_URL);
//    OCMStub([contextMock boolNamed:LPMT_ARG_LAYOUT_HEIGHT]).andReturn(LPMT_DEFAULT_HAS_DISMISS_BUTTON);
//    OCMStub([contextMock stringNamed:LPMT_ARG_URL]).andReturn(@"https://www.example.com");
//
//    LPWebInterstitialMessageTemplate *template = [[LPWebInterstitialMessageTemplate alloc] init];
//    UIViewController *viewController = [template viewControllerWithContext:context];
//
//    [LPMessageTemplateUtilities presentOverVisible:viewController];
//
//    XCTestExpectation *expects = [self expectationWithDescription:@"wait_for_load"];
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * 5.0), dispatch_get_main_queue(), ^{
//        FBSnapshotVerifyView(viewController.view, nil);
//        [expects fulfill];
//    });
//    [self waitForExpectationsWithTimeout:10.0 handler:nil];
//}

@end
