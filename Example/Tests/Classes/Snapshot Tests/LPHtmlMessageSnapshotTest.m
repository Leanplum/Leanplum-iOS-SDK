//
//  LPAlertMessageSnapshotTest.m
//  Leanplum-SDK_Tests
//
//  Created by Mayank Sanganeria on 2/25/20.
//  Copyright © 2020 Leanplum. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <FBSnapshotTestCase/FBSnapshotTestCase.h>
#import <Leanplum/LPHtmlMessageTemplate.h>
#import <OCMock.h>

@interface LPHtmlMessageTemplate()

@property  (nonatomic, strong) UIView *popupGroup;
- (void)setupPopupView;

@end

@interface LPActionContext(UnitTest)

+ (LPActionContext *)actionContextWithName:(NSString *)name
                                      args:(NSDictionary *)args
                                 messageId:(NSString *)messageId;

@end

@interface LPHtmlMessageSnapshotTest : FBSnapshotTestCase

@end

@implementation LPHtmlMessageSnapshotTest

- (void)setUp {
    [super setUp];
    self.recordMode = YES;
}

- (void)tearDown {
    [super tearDown];
}

- (void)testView {
    LPHtmlMessageTemplate *template = [[LPHtmlMessageTemplate alloc] init];
    LPActionContext *context = [LPActionContext actionContextWithName:LPMT_HTML_NAME args:@{
        LPMT_ARG_LAYOUT_WIDTH:@(LPMT_DEFAULT_CENTER_POPUP_WIDTH),
        LPMT_ARG_LAYOUT_HEIGHT:@(LPMT_DEFAULT_CENTER_POPUP_HEIGHT),
        LPMT_ARG_URL_CLOSE: LPMT_DEFAULT_CLOSE_URL,
        LPMT_ARG_URL_OPEN: LPMT_DEFAULT_OPEN_URL,
        LPMT_ARG_URL_TRACK: LPMT_DEFAULT_TRACK_URL,
        LPMT_ARG_URL_ACTION: LPMT_DEFAULT_ACTION_URL,
        LPMT_ARG_URL_TRACK_ACTION: LPMT_DEFAULT_TRACK_ACTION_URL,
        LPMT_ARG_HTML_ALIGN: LPMT_ARG_HTML_ALIGN_TOP,
        LPMT_ARG_HTML_HEIGHT: @0,
        LPMT_ARG_HTML_WIDTH: @"100%",
        LPMT_ARG_HTML_Y_OFFSET: @"0px",
        LPMT_ARG_HTML_TAP_OUTSIDE_TO_CLOSE: @NO,
        LPMT_HAS_DISMISS_BUTTON: @NO,
//        LPMT_ARG_HTML_TEMPLATE :nil
    } messageId:0];

    id contextMock = OCMPartialMock(context);
    OCMStub([contextMock numberNamed:LPMT_ARG_LAYOUT_WIDTH]).andReturn(@(LPMT_DEFAULT_CENTER_POPUP_WIDTH));
    OCMStub([contextMock numberNamed:LPMT_ARG_LAYOUT_HEIGHT]).andReturn(@(LPMT_DEFAULT_CENTER_POPUP_HEIGHT));
    OCMStub([contextMock stringNamed:LPMT_ARG_URL_CLOSE]).andReturn(LPMT_DEFAULT_CLOSE_URL);
    OCMStub([contextMock stringNamed:LPMT_ARG_URL_OPEN]).andReturn(LPMT_DEFAULT_OPEN_URL);
    OCMStub([contextMock stringNamed:LPMT_ARG_URL_TRACK]).andReturn(LPMT_DEFAULT_TRACK_URL);
    OCMStub([contextMock stringNamed:LPMT_ARG_URL_ACTION]).andReturn(LPMT_DEFAULT_ACTION_URL);
    OCMStub([contextMock stringNamed:LPMT_ARG_URL_TRACK_ACTION]).andReturn(LPMT_DEFAULT_TRACK_ACTION_URL);
    OCMStub([contextMock stringNamed:LPMT_ARG_HTML_ALIGN]).andReturn(LPMT_ARG_HTML_ALIGN_TOP);
    OCMStub([contextMock numberNamed:LPMT_ARG_HTML_HEIGHT]).andReturn(@0);
    OCMStub([contextMock stringNamed:LPMT_ARG_HTML_WIDTH]).andReturn(@"100%");
    OCMStub([contextMock stringNamed:LPMT_ARG_HTML_Y_OFFSET]).andReturn(@"0px");
    OCMStub([contextMock boolNamed:LPMT_ARG_HTML_TAP_OUTSIDE_TO_CLOSE]).andReturn(@NO);
    OCMStub([contextMock boolNamed:LPMT_HAS_DISMISS_BUTTON]).andReturn(@NO);

    template.contexts = [@[contextMock] mutableCopy];
    [template setupPopupView];
    FBSnapshotVerifyView(template.popupGroup, nil);
}

@end
