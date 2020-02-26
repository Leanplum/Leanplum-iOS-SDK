//
//  LPAlertMessageSnapshotTest.m
//  Leanplum-SDK_Tests
//
//  Created by Mayank Sanganeria on 2/25/20.
//  Copyright © 2020 Leanplum. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <FBSnapshotTestCase/FBSnapshotTestCase.h>
#import <Leanplum/LPAlertMessageTemplate.h>

@interface LPAlertMessageTemplate()

-(UIViewController *)viewControllerWithContext:(LPActionContext *)context;

@end

@interface LPActionContext(UnitTest)

+ (LPActionContext *)actionContextWithName:(NSString *)name
                                      args:(NSDictionary *)args
                                 messageId:(NSString *)messageId;

@end

@interface LPAlertMessageSnapshotTest : FBSnapshotTestCase

@end

@implementation LPAlertMessageSnapshotTest

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
    [super setUp];
//    self.recordMode = YES;
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testView {
    LPAlertMessageTemplate *template = [[LPAlertMessageTemplate alloc] init];
    LPActionContext *context = [LPActionContext actionContextWithName:LPMT_ALERT_NAME args:@{
        LPMT_ARG_TITLE:APP_NAME,
        LPMT_ARG_MESSAGE:LPMT_DEFAULT_ALERT_MESSAGE,
        LPMT_ARG_DISMISS_TEXT:LPMT_DEFAULT_OK_BUTTON_TEXT,
    } messageId:0];

    UIViewController* viewController = [template viewControllerWithContext:context];
    FBSnapshotVerifyView(viewController.view, nil);
}

@end
