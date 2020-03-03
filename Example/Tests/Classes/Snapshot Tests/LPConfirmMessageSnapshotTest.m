//
//  LPAlertMessageSnapshotTest.m
//  Leanplum-SDK_Tests
//
//  Created by Mayank Sanganeria on 2/25/20.
//  Copyright © 2020 Leanplum. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <FBSnapshotTestCase/FBSnapshotTestCase.h>
#import <Leanplum/LPConfirmMessageTemplate.h>

@interface LPConfirmMessageTemplate()

-(UIViewController *)viewControllerWithContext:(LPActionContext *)context;

@end

@interface LPActionContext(UnitTest)

+ (LPActionContext *)actionContextWithName:(NSString *)name
                                      args:(NSDictionary *)args
                                 messageId:(NSString *)messageId;

@end

@interface LPConfirmMessageSnapshotTest : FBSnapshotTestCase

@end

@implementation LPConfirmMessageSnapshotTest

- (void)setUp {
    [super setUp];
//    self.recordMode = YES;
}

- (void)tearDown {
    [super tearDown];
}

- (void)testView {
    LPConfirmMessageTemplate *template = [[LPConfirmMessageTemplate alloc] init];
    LPActionContext *context = [LPActionContext actionContextWithName:LPMT_CONFIRM_NAME args:@{
        LPMT_ARG_TITLE: APP_NAME,
        LPMT_ARG_MESSAGE: LPMT_DEFAULT_CONFIRM_MESSAGE,
        LPMT_ARG_ACCEPT_TEXT: LPMT_DEFAULT_YES_BUTTON_TEXT,
        LPMT_ARG_CANCEL_TEXT: LPMT_DEFAULT_NO_BUTTON_TEXT,
    } messageId:0];

    UIViewController* viewController = [template viewControllerWithContext:context];
    FBSnapshotVerifyView(viewController.view, nil);
}

@end
