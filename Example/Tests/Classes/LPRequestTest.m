//
//  LPRequestTest.m
//  Leanplum-SDK_Tests
//
//  Created by Mayank Sanganeria on 9/26/18.
//  Copyright © 2018 Leanplum. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <Leanplum/LPRequest.h>

@interface LPRequest(UnitTest)

@property (nonatomic, strong) NSString *apiMethod;
@property (nonatomic, strong, nullable) NSDictionary *params;
@property (nonatomic, strong) NSString *httpMethod;

@end

@interface LPRequestTest : XCTestCase

@end

@implementation LPRequestTest

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testPostShouldCreatePostRequest {
    NSString *apiMethod = @"apiMethod";
    NSDictionary *params = @{@"key": @"value"};
    LPRequest *postRequest = [LPRequest post:apiMethod params:params];

    XCTAssertEqual(postRequest.apiMethod, apiMethod);
    XCTAssertEqual(postRequest.params, params);
    XCTAssertTrue([postRequest.httpMethod isEqualToString:@"POST"]);
}

- (void)testGetShouldCreateGetRequest {
    NSString *apiMethod = @"apiMethod";
    NSDictionary *params = @{@"key": @"value"};
    LPRequest *getRequest = [LPRequest get:apiMethod params:params];

    XCTAssertEqual(getRequest.apiMethod, apiMethod);
    XCTAssertEqual(getRequest.params, params);
    XCTAssertTrue([getRequest.httpMethod isEqualToString:@"GET"]);
}

- (void)testCreateArgsDictionaryForRequest {
    LPRequest *request = [LPRequest post:@"test" params:@{}];
    LPConstantsState *constants = [LPConstantsState sharedState];
    NSString *timestamp = [NSString stringWithFormat:@"%f", [[NSDate date] timeIntervalSince1970]];
    NSMutableDictionary *testArgs = [@{
                                   LP_PARAM_ACTION: @"test",
                                   LP_PARAM_DEVICE_ID: @"",
                                   LP_PARAM_USER_ID: @"",
                                   LP_PARAM_SDK_VERSION: constants.sdkVersion,
                                   LP_PARAM_CLIENT: constants.client,
                                   LP_PARAM_DEV_MODE: @(constants.isDevelopmentModeEnabled),
                                   LP_PARAM_TIME: timestamp,
                                   LP_PARAM_UUID: @"uuid",
                                   LP_PARAM_REQUEST_ID: request.requestId,
                                   } mutableCopy];
    NSMutableDictionary *args = [request createArgsDictionary];
    args[LP_PARAM_UUID] = @"uuid";
    args[LP_PARAM_TIME] = timestamp;
    
    XCTAssertEqualObjects(testArgs, args);
}

@end
