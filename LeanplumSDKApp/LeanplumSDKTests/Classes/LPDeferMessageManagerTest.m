//
//  LPDeferMessageManagerTest.m
//  Leanplum-SDK_Tests
//
//  Created by Nikola Zagorchev on 26.08.20.
//  Copyright © 2020 Leanplum. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "Leanplum+Extensions.h"
#import "LeanplumHelper.h"
#import <Leanplum/LPDeferMessageManager.h>
#import <Leanplum/LPAlertMessageTemplate.h>

@interface LPDeferMessageManagerTest : XCTestCase

@end

@interface LPSampleViewController : UIViewController
@end
@implementation LPSampleViewController
@end

@implementation LPDeferMessageManagerTest

+ (void)setUp
{
    [super setUp];
    [LeanplumHelper mockThrowErrorToThrow];
    // Mock LOG_LP_MESSAGE_EXCEPTION through [LPLogManager maybeSendLog:]
    id mockLPLogManager = OCMClassMock([LPLogManager class]);
    [OCMStub(ClassMethod([mockLPLogManager maybeSendLog:[OCMArg any]])) andCall:@selector(maybeSendLog:) onObject:self];
    [LeanplumHelper stopMockThrowErrorToThrow];
}

/**
 * Throw exception if the log is coming from LOG_LP_MESSAGE_EXCEPTION
 */
+ (void)maybeSendLog:(NSString *)message {
    if ([message containsString:@"Error in message template"]) {
        @throw([NSException exceptionWithName:NSGenericException reason:message userInfo:nil]);
    }
}

/**
 * Defer message for controller and Alert message
 */
- (void)setupDeferMessage {
    NSArray<Class> *arr = @[[LPSampleViewController class]];
    [Leanplum deferMessagesForViewControllers: arr];
}

- (void)tearDown
{
    [super tearDown];
    [Leanplum reset];
    [LPDeferMessageManager reset];
}

- (void)test_defer
{
    [self setupDeferMessage];
    [LPAlertMessageTemplate defineAction];
    
    id templateUtils = OCMClassMock([LPMessageTemplateUtilities class]);
    id deferManager = OCMClassMock([LPDeferMessageManager class]);
    OCMStub([templateUtils topViewController]).andReturn([LPSampleViewController new]);
    
    LPActionContext *context = [LPActionContext actionContextWithName:LPMT_ALERT_NAME args:@{} messageId:0];
    
    OCMReject([templateUtils presentOverVisible:OCMArg.any]);

    XCTestExpectation *expectation = [self expectationWithDescription:@"Message is not handled"];
    [Leanplum triggerAction:context handledBlock:^(BOOL success) {
        XCTAssertFalse(success);
        [expectation fulfill];
    }];
    
    OCMVerify([deferManager shouldDeferMessage:OCMArg.any]);
    
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Error: %@", error);
        }
    }];
}

- (void)test_no_defer
{
    // Leanplum start is needed to successfully handle message View and record impression
    [LeanplumHelper start_development_test];
    
    [LPAlertMessageTemplate defineAction];
    
    id templateUtils = OCMClassMock([LPMessageTemplateUtilities class]);
    id deferManager = OCMClassMock([LPDeferMessageManager class]);
    
    LPActionContext *context = [LPActionContext actionContextWithName:LPMT_ALERT_NAME args:@{} messageId:0];

    XCTestExpectation *expectation = [self expectationWithDescription:@"Message is not handled"];
    [Leanplum triggerAction:context handledBlock:^(BOOL success) {
        XCTAssertTrue(success);
        [expectation fulfill];
    }];
    
    OCMVerify([deferManager shouldDeferMessage:OCMArg.any]);
    OCMVerify([templateUtils presentOverVisible:OCMArg.any]);
    
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Error: %@", error);
        }
    }];
}

- (void)test_defer_and_show
{
    // Leanplum start is needed to successfully handle message View and record impression
    [LeanplumHelper start_development_test];
    
    [self setupDeferMessage];
    
    [LPAlertMessageTemplate defineAction];
    
    id templateUtils = OCMClassMock([LPMessageTemplateUtilities class]);
    id deferManager = OCMClassMock([LPDeferMessageManager class]);
    id stub = OCMStub([templateUtils topViewController]);
    [stub andReturn:[LPSampleViewController new]];
    
    LPActionContext *context = [LPActionContext actionContextWithName:LPMT_ALERT_NAME args:@{} messageId:@"123"];

    XCTestExpectation *expectation = [self expectationWithDescription:@"Message is not handled"];
    [Leanplum triggerAction:context handledBlock:^(BOOL success) {
        XCTAssertFalse(success);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Error: %@", error);
        }
    }];
    
    id lpMock = OCMClassMock([Leanplum class]);
    
    // Change the top controller to show the deferred message
    UIViewController *newTopViewController = [UIViewController new];
    [stub andReturn:newTopViewController];
    [newTopViewController viewDidAppear:NO];
    
    OCMVerify([deferManager triggerDeferredMessage]);
    OCMVerify([templateUtils presentOverVisible:OCMArg.any]);
    OCMVerify([lpMock triggerAction:context handledBlock:OCMArg.any]);
    
    [lpMock stopMocking];
}

@end
