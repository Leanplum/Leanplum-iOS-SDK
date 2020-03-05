//
//  LPAlertMessageSnapshotTest.m
//  Leanplum-SDK_Tests
//
//  Created by Mayank Sanganeria on 2/25/20.
//  Copyright © 2020 Leanplum. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <FBSnapshotTestCase/FBSnapshotTestCase.h>
#import <Leanplum/LPPushAsktoAskMessageTemplate.h>
#import <OCMock.h>

@interface LPPushAsktoAskMessageTemplate()

@property  (nonatomic, strong) UIView *popupGroup;
- (void)setupPopupView;

@end

@interface LPActionContext(UnitTest)

+ (LPActionContext *)actionContextWithName:(NSString *)name
                                      args:(NSDictionary *)args
                                 messageId:(NSString *)messageId;

@end

@interface LPPushAskToAskMessageSnapshotTest : FBSnapshotTestCase

@end

@implementation LPPushAskToAskMessageSnapshotTest

- (void)setUp {
    [super setUp];
    //self.recordMode = YES;
}

- (void)tearDown {
    [super tearDown];
}

- (void)testView {
    LPPushAsktoAskMessageTemplate *template = [[LPPushAsktoAskMessageTemplate alloc] init];

    LPActionContext *context = [LPActionContext actionContextWithName:LPMT_PUSH_ASK_TO_ASK args:@{
        LPMT_ARG_TITLE_TEXT:APP_NAME,
        LPMT_ARG_TITLE_COLOR:[UIColor blackColor],
        LPMT_ARG_MESSAGE_TEXT:LPMT_DEFAULT_ASK_TO_ASK_MESSAGE,
        LPMT_ARG_MESSAGE_COLOR:[UIColor blackColor],
        LPMT_ARG_BACKGROUND_COLOR:[UIColor colorWithWhite:LIGHT_GRAY alpha:1.0],
        LPMT_ARG_ACCEPT_BUTTON_TEXT:LPMT_DEFAULT_OK_BUTTON_TEXT,
        LPMT_ARG_ACCEPT_BUTTON_BACKGROUND_COLOR:[UIColor colorWithWhite:LIGHT_GRAY alpha:1.0],
        LPMT_ARG_ACCEPT_BUTTON_TEXT_COLOR:[UIColor blackColor],
        LPMT_ARG_CANCEL_BUTTON_TEXT:LPMT_DEFAULT_LATER_BUTTON_TEXT,
        LPMT_ARG_CANCEL_BUTTON_BACKGROUND_COLOR:[UIColor colorWithWhite:LIGHT_GRAY alpha:1.0],
        LPMT_ARG_CANCEL_BUTTON_TEXT_COLOR:[UIColor grayColor],
        LPMT_ARG_LAYOUT_WIDTH:@(LPMT_DEFAULT_CENTER_POPUP_WIDTH),
        LPMT_ARG_LAYOUT_HEIGHT:@(LPMT_DEFAULT_CENTER_POPUP_HEIGHT)
    } messageId:0];
    id contextMock = OCMPartialMock(context);
    OCMStub([contextMock stringNamed:LPMT_ARG_TITLE_TEXT]).andReturn(APP_NAME);
    OCMStub([contextMock colorNamed:LPMT_ARG_TITLE_COLOR]).andReturn([UIColor blackColor]);
    OCMStub([contextMock stringNamed:LPMT_ARG_MESSAGE_TEXT]).andReturn(LPMT_DEFAULT_ASK_TO_ASK_MESSAGE);
    OCMStub([contextMock colorNamed:LPMT_ARG_MESSAGE_COLOR]).andReturn([UIColor blackColor]);
    OCMStub([contextMock colorNamed:LPMT_ARG_BACKGROUND_COLOR]).andReturn([UIColor colorWithWhite:LIGHT_GRAY alpha:1.0]);
    OCMStub([contextMock stringNamed:LPMT_ARG_ACCEPT_BUTTON_TEXT]).andReturn(LPMT_DEFAULT_OK_BUTTON_TEXT);
    OCMStub([contextMock colorNamed:LPMT_ARG_ACCEPT_BUTTON_BACKGROUND_COLOR]).andReturn([UIColor colorWithWhite:LIGHT_GRAY alpha:1.0]);
    OCMStub([contextMock colorNamed:LPMT_ARG_ACCEPT_BUTTON_TEXT_COLOR]).andReturn([UIColor blackColor]);
    OCMStub([contextMock stringNamed:LPMT_ARG_CANCEL_BUTTON_TEXT]).andReturn(LPMT_DEFAULT_LATER_BUTTON_TEXT);
    OCMStub([contextMock colorNamed:LPMT_ARG_CANCEL_BUTTON_BACKGROUND_COLOR]).andReturn([UIColor colorWithWhite:LIGHT_GRAY alpha:1.0]);
    OCMStub([contextMock colorNamed:LPMT_ARG_CANCEL_BUTTON_TEXT_COLOR]).andReturn([UIColor grayColor]);
    OCMStub([contextMock numberNamed:LPMT_ARG_LAYOUT_WIDTH]).andReturn(@(LPMT_DEFAULT_CENTER_POPUP_WIDTH));
    OCMStub([contextMock numberNamed:LPMT_ARG_LAYOUT_HEIGHT]).andReturn(@(LPMT_DEFAULT_CENTER_POPUP_HEIGHT));

    template.contexts = [@[contextMock] mutableCopy];
    [template setupPopupView];
    FBSnapshotVerifyView(template.popupGroup, nil);
}

@end
