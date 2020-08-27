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
#import "Leanplum/LPActionResponder.h"
#import "Leanplum+Extensions.h"
#import "LeanplumHelper.h"

@interface LPActionResponderTest : XCTestCase

@end

@implementation LPActionResponderTest

- (void)test_init
{
    LPActionResponder *responder = [LPActionResponder initWithResponder:^BOOL (LPActionContext *c){
        return NO;
    }];
    
    XCTAssertFalse(responder.isPostponable);
}

- (void)test_init_postpone
{
    LPActionResponder *responder = [LPActionResponder initWithPostponableResponder:^BOOL (LPActionContext *c){
        return NO;
    }];
    
    XCTAssertTrue(responder.isPostponable);
}

- (void)test_init_responder
{
    LPActionContext *context = [LPActionContext actionContextWithName:LPMT_ALERT_NAME args:@{} messageId:0];
    
    LPActionResponder *responder = [LPActionResponder initWithResponder:^BOOL (LPActionContext *c){
        return YES;
    }];
    
    XCTAssertTrue(responder.actionBlock(context));
    
    LPActionResponder *responderPostpone = [LPActionResponder initWithPostponableResponder:^BOOL (LPActionContext *c){
        return NO;
    }];
    
    XCTAssertFalse(responderPostpone.actionBlock(context));
}
@end
