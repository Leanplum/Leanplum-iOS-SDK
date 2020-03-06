//
//  LPAlertMessageSnapshotTest.m
//  Leanplum-SDK_Tests
//
//  Created by Mayank Sanganeria on 2/25/20.
//  Copyright © 2020 Leanplum. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <FBSnapshotTestCase/FBSnapshotTestCase.h>
#import <Leanplum/LPInterstitialMessageTemplate.h>
#import <OCMock.h>

@interface LPInterstitialMessageTemplate()

@property  (nonatomic, strong) UIView *popupGroup;
- (void)setupPopupView;

@end

@interface LPActionContext(UnitTest)

+ (LPActionContext *)actionContextWithName:(NSString *)name
                                      args:(NSDictionary *)args
                                 messageId:(NSString *)messageId;

@end

@interface LPInterstitialMessageSnapshotTest : FBSnapshotTestCase

@end

@implementation LPInterstitialMessageSnapshotTest

- (void)setUp {
    [super setUp];
    //self.recordMode = YES;
}

- (void)tearDown {
    [super tearDown];
}

- (void)testView {
    LPInterstitialMessageTemplate *template = [[LPInterstitialMessageTemplate alloc] init];
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

    template.contexts = [@[contextMock] mutableCopy];
    [template setupPopupView];
    FBSnapshotVerifyView(template.popupGroup, nil);
}

@end
