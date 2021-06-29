#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import <OHHTTPStubs/HTTPStubs.h>
#import <OHHTTPStubs/HTTPStubsPathHelpers.h>
#import "LeanplumHelper.h"
#import "Leanplum+Extensions.h"

@interface LPLocalCapsTest : XCTestCase

@end

@implementation LPLocalCapsTest

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [LeanplumHelper clean_up];
    [super tearDown];
}

- (void)testParseSessionLimit {
    id<HTTPStubsDescriptor> startStub = [HTTPStubs stubRequestsPassingTest:
                                           ^BOOL(NSURLRequest * _Nonnull request) {
        return [request.URL.host isEqualToString:API_HOST];
    } withStubResponse:^HTTPStubsResponse * _Nonnull(NSURLRequest * _Nonnull request) {
        NSString *response_file = OHPathForFile(@"local_caps_session_response.json", self.class);
        return [HTTPStubsResponse responseWithFileAtPath:response_file statusCode:200
                                                   headers:@{@"Content-Type":@"application/json"}];
    }];
    
    NSMutableDictionary *session = [[NSMutableDictionary alloc] init];
    [session setValue:@"IN_APP" forKey:@"channel"];
    [session setValue:@5 forKey:@"limit"];
    [session setValue:@"SESSION" forKey:@"type"];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Local caps are parsed"];
    [Leanplum startWithResponseHandler:^(BOOL success) {
        [HTTPStubs removeStub:startStub];
        
        NSArray *caps = [[LPVarCache sharedCache] getLocalCaps];
        XCTAssertEqual([caps count], 1);
        XCTAssertTrue([caps containsObject:session]);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:10 handler:nil];
}

- (void)testParseDayLimit {
    id<HTTPStubsDescriptor> startStub = [HTTPStubs stubRequestsPassingTest:
                                           ^BOOL(NSURLRequest * _Nonnull request) {
        return [request.URL.host isEqualToString:API_HOST];
    } withStubResponse:^HTTPStubsResponse * _Nonnull(NSURLRequest * _Nonnull request) {
        NSString *response_file = OHPathForFile(@"local_caps_day_response.json", self.class);
        return [HTTPStubsResponse responseWithFileAtPath:response_file statusCode:200
                                                   headers:@{@"Content-Type":@"application/json"}];
    }];
    
    NSMutableDictionary *day = [[NSMutableDictionary alloc] init];
    [day setValue:@"IN_APP" forKey:@"channel"];
    [day setValue:@25 forKey:@"limit"];
    [day setValue:@"DAY" forKey:@"type"];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Local caps are parsed"];
    [Leanplum startWithResponseHandler:^(BOOL success) {
        [HTTPStubs removeStub:startStub];
        
        NSArray *caps = [[LPVarCache sharedCache] getLocalCaps];
        XCTAssertEqual([caps count], 1);
        XCTAssertTrue([caps containsObject:day]);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:10 handler:nil];
}

- (void)testParseWeekLimit {
    id<HTTPStubsDescriptor> startStub = [HTTPStubs stubRequestsPassingTest:
                                           ^BOOL(NSURLRequest * _Nonnull request) {
        return [request.URL.host isEqualToString:API_HOST];
    } withStubResponse:^HTTPStubsResponse * _Nonnull(NSURLRequest * _Nonnull request) {
        NSString *response_file = OHPathForFile(@"local_caps_week_response.json", self.class);
        return [HTTPStubsResponse responseWithFileAtPath:response_file statusCode:200
                                                   headers:@{@"Content-Type":@"application/json"}];
    }];
    
    NSMutableDictionary *week = [[NSMutableDictionary alloc] init];
    [week setValue:@"IN_APP" forKey:@"channel"];
    [week setValue:@100 forKey:@"limit"];
    [week setValue:@"WEEK" forKey:@"type"];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Local caps are parsed"];
    [Leanplum startWithResponseHandler:^(BOOL success) {
        [HTTPStubs removeStub:startStub];
        
        NSArray *caps = [[LPVarCache sharedCache] getLocalCaps];
        XCTAssertEqual([caps count], 1);
        XCTAssertTrue([caps containsObject:week]);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:10 handler:nil];
}

- (void)testParseAll {
    id<HTTPStubsDescriptor> startStub = [HTTPStubs stubRequestsPassingTest:
                                           ^BOOL(NSURLRequest * _Nonnull request) {
        return [request.URL.host isEqualToString:API_HOST];
    } withStubResponse:^HTTPStubsResponse * _Nonnull(NSURLRequest * _Nonnull request) {
        NSString *response_file = OHPathForFile(@"local_caps_response.json", self.class);
        return [HTTPStubsResponse responseWithFileAtPath:response_file statusCode:200
                                                   headers:@{@"Content-Type":@"application/json"}];
    }];
    
    NSMutableDictionary *session = [[NSMutableDictionary alloc] init];
    [session setValue:@"IN_APP" forKey:@"channel"];
    [session setValue:@1 forKey:@"limit"];
    [session setValue:@"SESSION" forKey:@"type"];
    
    NSMutableDictionary *day = [[NSMutableDictionary alloc] init];
    [day setValue:@"IN_APP" forKey:@"channel"];
    [day setValue:@2 forKey:@"limit"];
    [day setValue:@"DAY" forKey:@"type"];
    
    NSMutableDictionary *week = [[NSMutableDictionary alloc] init];
    [week setValue:@"IN_APP" forKey:@"channel"];
    [week setValue:@3 forKey:@"limit"];
    [week setValue:@"WEEK" forKey:@"type"];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Local caps are parsed"];
    [Leanplum startWithResponseHandler:^(BOOL success) {
        [HTTPStubs removeStub:startStub];
        
        NSArray *caps = [[LPVarCache sharedCache] getLocalCaps];
        XCTAssertEqual([caps count], 3);
        XCTAssertTrue([caps containsObject:session]);
        XCTAssertTrue([caps containsObject:day]);
        XCTAssertTrue([caps containsObject:week]);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:10 handler:nil];
}

@end
