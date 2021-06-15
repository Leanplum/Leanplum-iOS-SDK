#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import <OHHTTPStubs/HTTPStubs.h>
#import <OHHTTPStubs/HTTPStubsPathHelpers.h>
#import "LeanplumHelper.h"
#import "Leanplum+Extensions.h"

@interface LPSecuredVarsTest : XCTestCase

@end

@implementation LPSecuredVarsTest

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    [super tearDown];
    [LeanplumHelper clean_up];
}

- (void)testVarsAndSignature {
    // This stub have to be removed when start command is successfully executed.
    id<HTTPStubsDescriptor> startStub = [HTTPStubs stubRequestsPassingTest:
                                           ^BOOL(NSURLRequest * _Nonnull request) {
        return [request.URL.host isEqualToString:API_HOST];
    } withStubResponse:^HTTPStubsResponse * _Nonnull(NSURLRequest * _Nonnull request) {
        NSString *response_file = OHPathForFile(@"secured_vars_response.json", self.class);
        return [HTTPStubsResponse responseWithFileAtPath:response_file statusCode:200
                                                   headers:@{@"Content-Type":@"application/json"}];
    }];
    
    [Leanplum startWithResponseHandler:^(BOOL success) {
        [HTTPStubs removeStub:startStub];
        LPSecuredVars *securedVars = [[LPVarCache sharedCache] securedVars];
        
        XCTAssertTrue([[securedVars varsJson] containsString:@"intVariable"]);
        XCTAssertTrue([[securedVars varsJson] containsString:@"stringVariable"]);
        
        XCTAssertTrue([[securedVars varsSignature] containsString:@"sign_of_vars"]);
    }];
}

- (void)testVarsNoSignature {
    // This stub have to be removed when start command is successfully executed.
    id<HTTPStubsDescriptor> startStub = [HTTPStubs stubRequestsPassingTest:
                                           ^BOOL(NSURLRequest * _Nonnull request) {
        return [request.URL.host isEqualToString:API_HOST];
    } withStubResponse:^HTTPStubsResponse * _Nonnull(NSURLRequest * _Nonnull request) {
        NSString *response_file = OHPathForFile(@"secured_vars_no_sign_response.json", self.class);
        return [HTTPStubsResponse responseWithFileAtPath:response_file statusCode:200
                                                   headers:@{@"Content-Type":@"application/json"}];
    }];
    
    [Leanplum startWithResponseHandler:^(BOOL success) {
        [HTTPStubs removeStub:startStub];
        
        LPSecuredVars *securedVars = [[LPVarCache sharedCache] securedVars];
        
        XCTAssertNil(securedVars);
    }];
}

- (void)testEmptyVarsNoSignature {
    // This stub have to be removed when start command is successfully executed.
    id<HTTPStubsDescriptor> startStub = [HTTPStubs stubRequestsPassingTest:
                                           ^BOOL(NSURLRequest * _Nonnull request) {
        return [request.URL.host isEqualToString:API_HOST];
    } withStubResponse:^HTTPStubsResponse * _Nonnull(NSURLRequest * _Nonnull request) {
        NSString *response_file = OHPathForFile(@"secured_vars_empty_response.json", self.class);
        return [HTTPStubsResponse responseWithFileAtPath:response_file statusCode:200
                                                   headers:@{@"Content-Type":@"application/json"}];
    }];
    
    [Leanplum startWithResponseHandler:^(BOOL success) {
        [HTTPStubs removeStub:startStub];
    
        LPSecuredVars *securedVars = [[LPVarCache sharedCache] securedVars];
        
        XCTAssertNil(securedVars);
    }];
}

@end
