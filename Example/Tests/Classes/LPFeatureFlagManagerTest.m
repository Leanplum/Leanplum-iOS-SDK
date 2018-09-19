//
//  LPFeatureFlagsManagerTest.m
//  Leanplum-SDK_Tests
//
//  Created by Grace on 9/18/18.
//  Copyright © 2018 Leanplum. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "LPFeatureFlagManager.h"
#import "Constants.h"

/**
 * Expose private class methods
 */

@interface LPFeatureFlagManagerTest : XCTestCase

@end

@implementation LPFeatureFlagManagerTest

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)test_isFeatureFlagEnabled {
    LPFeatureFlagManager *featureFlagManager = [[LPFeatureFlagManager alloc] init];
    
    NSString *testString = @"test";
    NSString *testString2 = @"test2";
    
    XCTAssert([featureFlagManager isFeatureFlagEnabled:testString] == false);
    
    featureFlagManager.enabledFeatureFlags = [NSSet setWithObjects:testString, nil];
    XCTAssert([featureFlagManager isFeatureFlagEnabled:testString] == true);
    XCTAssert([featureFlagManager isFeatureFlagEnabled:testString2] == false);
    
    featureFlagManager.enabledFeatureFlags = [NSSet setWithObjects:testString, testString2, nil];
    XCTAssert([featureFlagManager isFeatureFlagEnabled:testString2] == true);
    
    featureFlagManager.enabledFeatureFlags = nil;
    XCTAssert([featureFlagManager isFeatureFlagEnabled:testString2] == false);
}

@end
