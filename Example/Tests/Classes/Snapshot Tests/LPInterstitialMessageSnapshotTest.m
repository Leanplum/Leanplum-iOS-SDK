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
//#import <Leanplum/LPInterstitialMessageTemplate.h>
//
//@interface LPInterstitialMessageTemplate()
//
//-(UIViewController *)viewControllerWithContext:(LPActionContext *)context;
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
//@interface LPInterstitialMessageSnapshotTest : FBSnapshotTestCase
//
//@end
//
//@implementation LPInterstitialMessageSnapshotTest
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
//    LPInterstitialMessageTemplate *template = [[LPInterstitialMessageTemplate alloc] init];
//    LPActionContext *context = [LPActionContext actionContextWithName:LPMT_Interstitial_NAME args:@{
//        LPMT_ARG_TITLE: APP_NAME,
//        LPMT_ARG_MESSAGE: LPMT_DEFAULT_Interstitial_MESSAGE,
//        LPMT_ARG_ACCEPT_TEXT: LPMT_DEFAULT_YES_BUTTON_TEXT,
//        LPMT_ARG_CANCEL_TEXT: LPMT_DEFAULT_NO_BUTTON_TEXT,
//    } messageId:0];
//
//    UIViewController* viewController = [template viewControllerWithContext:context];
//    FBSnapshotVerifyView(viewController.view, nil);
//}
//
//@end
