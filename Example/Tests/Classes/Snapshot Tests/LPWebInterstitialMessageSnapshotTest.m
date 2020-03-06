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

@interface LPWebInterstitialMessageSnapshotTest : FBSnapshotTestCase

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
    LPWebInterstitialMessageTemplate *template = [[LPWebInterstitialMessageTemplate alloc] init];
    LPActionContext *context = [LPActionContext actionContextWithName:LPMT_WEB_INTERSTITIAL_NAME args:@{
        LPMT_ARG_URL:LPMT_DEFAULT_URL,
        LPMT_ARG_URL_CLOSE:LPMT_DEFAULT_CLOSE_URL,
        LPMT_HAS_DISMISS_BUTTON:@(LPMT_DEFAULT_HAS_DISMISS_BUTTON),
    } messageId:0];
    id contextMock = OCMPartialMock(context);
    OCMStub([contextMock stringNamed:LPMT_ARG_TITLE_TEXT]).andReturn(LPMT_DEFAULT_URL);
    OCMStub([contextMock stringNamed:LPMT_ARG_MESSAGE_TEXT]).andReturn(LPMT_DEFAULT_CLOSE_URL);
    OCMStub([contextMock boolNamed:LPMT_ARG_LAYOUT_HEIGHT]).andReturn(@(LPMT_DEFAULT_HAS_DISMISS_BUTTON));
    
    template.contexts = [@[contextMock] mutableCopy];
    [template setupPopupView];
    sleep(5);
    FBSnapshotVerifyView(template.popupGroup, nil);
}

@end
