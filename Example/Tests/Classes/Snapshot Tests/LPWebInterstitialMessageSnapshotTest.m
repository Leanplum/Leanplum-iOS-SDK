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

@interface LPWebInterstitialMessageTemplate()

@property  (nonatomic, strong) UIView *popupGroup;
@property  (nonatomic, strong) WKWebView *popupView;
- (void)setupPopupView;

@end

@interface LPActionContext(UnitTest)

+ (LPActionContext *)actionContextWithName:(NSString *)name
                                      args:(NSDictionary *)args
                                 messageId:(NSString *)messageId;

@end

@interface LPWebInterstitialMessageSnapshotTest : FBSnapshotTestCase <WKNavigationDelegate>

@end

@implementation LPWebInterstitialMessageSnapshotTest

- (void)setUp {
    [super setUp];
    //self.recordMode = YES;
}

- (void)tearDown {
    [super tearDown];
}

// commenting out until we can get this to run on CI
- (void)testView {
    // LPWebInterstitialMessageTemplate *tmplate = [[LPWebInterstitialMessageTemplate alloc] init];
    // LPActionContext *context = [LPActionContext actionContextWithName:LPMT_WEB_INTERSTITIAL_NAME args:@{
    //     LPMT_ARG_URL:LPMT_DEFAULT_URL,
    //     LPMT_ARG_URL_CLOSE:LPMT_DEFAULT_CLOSE_URL,
    //     LPMT_HAS_DISMISS_BUTTON:@(LPMT_DEFAULT_HAS_DISMISS_BUTTON),
    // } messageId:0];
    // id contextMock = OCMPartialMock(context);
    // OCMStub([contextMock stringNamed:LPMT_ARG_TITLE_TEXT]).andReturn(LPMT_DEFAULT_URL);
    // OCMStub([contextMock stringNamed:LPMT_ARG_MESSAGE_TEXT]).andReturn(LPMT_DEFAULT_CLOSE_URL);
    // OCMStub([contextMock boolNamed:LPMT_ARG_LAYOUT_HEIGHT]).andReturn(LPMT_DEFAULT_HAS_DISMISS_BUTTON);
    // OCMStub([contextMock stringNamed:LPMT_ARG_URL]).andReturn(@"https://www.google.com");

    // tmplate.contexts = [@[contextMock] mutableCopy];
    // [tmplate setupPopupView];
    // XCTestExpectation *expects = [self expectationWithDescription:@"wait_for_load"];
    // dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * 15.0), dispatch_get_main_queue(), ^{
    //     if (@available(iOS 11.0, *)) {
    //         [tmplate.popupView takeSnapshotWithConfiguration:nil completionHandler:^(UIImage * _Nullable snapshotImage, NSError * _Nullable error) {
    //             UIImageView *imgView = [[UIImageView alloc] initWithImage:snapshotImage];
    //             FBSnapshotVerifyViewWithOptions(imgView, @"webContent", nil, 0.5);
    //             FBSnapshotVerifyView(tmplate.popupGroup, @"viewShell");
    //             [expects fulfill];
    //         }];
    //     } else {
    //         // Fallback on earlier versions
    //     }
    // });
    // [self waitForExpectationsWithTimeout:20.0 handler:nil];
}

@end
