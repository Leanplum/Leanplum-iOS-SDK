////
////  LPAlertMessageSnapshotTest.m
////  Leanplum-SDK_Tests
////
////  Created by Mayank Sanganeria on 2/25/20.
////  Copyright © 2020 Leanplum. All rights reserved.
////
//
//#import <XCTest/XCTest.h>
//#import <FBSnapshotTestCase/FBSnapshotTestCase.h>
//#import <Leanplum/LPCenterPopupMessageTemplate.h>
//
//@interface LPCenterPopupMessageTemplate()
//
//@property  (nonatomic, strong) UIView *popupGroup;
//- (void)setupPopupViewWithContext:(LPActionContext *)context;
//
//@end
//
//@interface LPActionContext(UnitTest)
//
//+ (LPActionContext *)actionContextWithName:(NSString *)name
//                                      args:(NSDictionary *)args
//                                 messageId:(NSString *)messageId;
//
//@end
//
//@interface LPCenterPopupMessageSnapshotTest : FBSnapshotTestCase
//
//@end
//
//@implementation LPCenterPopupMessageSnapshotTest
//
//- (void)setUp {
//    [super setUp];
////    self.recordMode = YES;
//}
//
//- (void)tearDown {
//    [super tearDown];
//}
//
//- (void)testView {
//    LPCenterPopupMessageTemplate *template = [[LPCenterPopupMessageTemplate alloc] init];
//    LPActionContext *context = [LPActionContext actionContextWithName:LPMT_CENTER_POPUP_NAME args:@{
//        LPMT_ARG_TITLE_TEXT:APP_NAME,
//        LPMT_ARG_TITLE_COLOR:[UIColor blackColor],
//        LPMT_ARG_MESSAGE_TEXT:LPMT_DEFAULT_POPUP_MESSAGE,
//        LPMT_ARG_MESSAGE_COLOR:[UIColor blackColor],
//        LPMT_ARG_BACKGROUND_COLOR:[UIColor whiteColor],
//        LPMT_ARG_ACCEPT_BUTTON_TEXT:LPMT_DEFAULT_OK_BUTTON_TEXT,
//        LPMT_ARG_ACCEPT_BUTTON_BACKGROUND_COLOR:[UIColor whiteColor],
////        LPMT_ARG_ACCEPT_BUTTON_TEXT_COLOR:defaultButtonTextColor,
//        LPMT_ARG_LAYOUT_WIDTH:@(LPMT_DEFAULT_CENTER_POPUP_WIDTH),
//        LPMT_ARG_LAYOUT_HEIGHT:@(LPMT_DEFAULT_CENTER_POPUP_HEIGHT),
//    }
//                                                            messageId:0];
//    [template setupPopupViewWithContext:context];
//    FBSnapshotVerifyView(template.popupGroup, nil);
//}
//
//@end
