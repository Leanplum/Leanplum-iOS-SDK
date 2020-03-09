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
    self.recordMode = YES;
}

- (void)tearDown {
    [super tearDown];
}

- (void)testView {
//    LPWebInterstitialMessageTemplate *template = [[LPWebInterstitialMessageTemplate alloc] init];
//    LPActionContext *context = [LPActionContext actionContextWithName:LPMT_WEB_INTERSTITIAL_NAME args:@{
//        LPMT_ARG_URL:LPMT_DEFAULT_URL,
//        LPMT_ARG_URL_CLOSE:LPMT_DEFAULT_CLOSE_URL,
//        LPMT_HAS_DISMISS_BUTTON:@(LPMT_DEFAULT_HAS_DISMISS_BUTTON),
//    } messageId:0];
//    id contextMock = OCMPartialMock(context);
//    OCMStub([contextMock stringNamed:LPMT_ARG_TITLE_TEXT]).andReturn(LPMT_DEFAULT_URL);
//    OCMStub([contextMock stringNamed:LPMT_ARG_MESSAGE_TEXT]).andReturn(LPMT_DEFAULT_CLOSE_URL);
//    OCMStub([contextMock boolNamed:LPMT_ARG_LAYOUT_HEIGHT]).andReturn(LPMT_DEFAULT_HAS_DISMISS_BUTTON);
//
//    template.contexts = [@[contextMock] mutableCopy];
//    [template setupPopupView];
//    sleep(5);
//    FBSnapshotVerifyView(template.popupGroup, nil);
    WKWebView *v = [[WKWebView alloc] initWithFrame:CGRectMake(0, 0, 500, 900)];
    v.navigationDelegate = self;
    v.backgroundColor = [UIColor redColor];
    NSURLRequest *r = [NSURLRequest requestWithURL:[NSURL URLWithString:@"https://www.google.com"]];
    [v loadRequest:r];
    XCTestExpectation *expects = [self expectationWithDescription:@"wait_for_load"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * 5.0), dispatch_get_main_queue(), ^{
        FBSnapshotVerifyView(v, nil);
        [expects fulfill];
    });
    [self waitForExpectationsWithTimeout:10 handler:nil];
}


//- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
//
//}
- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(null_unspecified WKNavigation *)navigation {

}
- (void)webView:(WKWebView *)webView didReceiveServerRedirectForProvisionalNavigation:(null_unspecified WKNavigation *)navigation {

}
- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error {

}
- (void)webView:(WKWebView *)webView didCommitNavigation:(null_unspecified WKNavigation *)navigation {

}
- (void)webView:(WKWebView *)webView didFinishNavigation:(null_unspecified WKNavigation *)navigation {
    webView.backgroundColor = [UIColor yellowColor];
}
- (void)webView:(WKWebView *)webView didFailNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error {


}
@end
