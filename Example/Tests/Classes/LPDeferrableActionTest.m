//
//  LPActionResponderTest.m
//  Leanplum-SDK_Tests
//
//  Created by Nikola Zagorchev on 25.08.20.
//  Copyright © 2020 Leanplum. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "Leanplum/LPDeferrableAction.h"
#import "Leanplum+Extensions.h"
#import "LeanplumHelper.h"

@interface LPDeferrableActionTest : XCTestCase

@end

@implementation LPDeferrableActionTest

- (void)test_init
{
    LPDeferrableAction *responder = [LPDeferrableAction initWithActionBlock:^BOOL (LPActionContext *c){
        return NO;
    }];
    
    XCTAssertFalse(responder.isDeferrable);
}

- (void)test_init_postpone
{
    LPDeferrableAction *responder = [LPDeferrableAction initWithDeferrableActionBlock:^BOOL (LPActionContext *c){
        return NO;
    }];
    
    XCTAssertTrue(responder.isDeferrable);
}

- (void)test_init_responder
{
    LPActionContext *context = [LPActionContext actionContextWithName:LPMT_ALERT_NAME args:@{} messageId:0];
    
    LPDeferrableAction *responder = [LPDeferrableAction initWithActionBlock:^BOOL (LPActionContext *c){
        return YES;
    }];
    
    XCTAssertTrue(responder.actionBlock(context));
    
    LPDeferrableAction *responderPostpone = [LPDeferrableAction initWithDeferrableActionBlock:^BOOL (LPActionContext *c){
        return NO;
    }];
    
    XCTAssertFalse(responderPostpone.actionBlock(context));
}
@end
