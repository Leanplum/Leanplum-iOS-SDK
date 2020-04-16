//
//  LPOpenUrlMessageTemplateTest.m
//  Leanplum-SDK_Tests
//
//  Created by Dejan . Krstevski on 16.04.20.
//  Copyright © 2020 Leanplum. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <Leanplum/LPOpenUrlMessageTemplate.h>
#import "Leanplum+Extensions.h"
#import "LPOpenUrlMessageTemplate+Extenstion.h"

@interface LPOpenUrlMessageTemplateTest : XCTestCase

@end

@implementation LPOpenUrlMessageTemplateTest

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testThatURLEncodingWorksForUnreservedCharacters {
    //Test characters  @":-._~/?&=#"
    // Note: all of them includes : . / charachers
    
    NSString *url;
    LPOpenUrlMessageTemplate * template;
    NSString * encodedURL;
    
    //test for # sign
    url = @"http://test.com/test#end";
    template = [self createTemplateWithUrl:url];
    encodedURL= [template urlEncodedStringFromString:[template.context stringNamed:LPMT_ARG_URL]];
    XCTAssertEqualObjects(url, encodedURL);
    
    //test for = sign
    url = @"http://test.com/test=end";
    template = [self createTemplateWithUrl:url];
    encodedURL= [template urlEncodedStringFromString:[template.context stringNamed:LPMT_ARG_URL]];
    XCTAssertEqualObjects(url, encodedURL);
    
    //test for & sign
    url = @"http://test.com/test&end";
    template = [self createTemplateWithUrl:url];
    encodedURL= [template urlEncodedStringFromString:[template.context stringNamed:LPMT_ARG_URL]];
    XCTAssertEqualObjects(url, encodedURL);
    
    //test for ? sign
    url = @"http://test.com/test?end";
    template = [self createTemplateWithUrl:url];
    encodedURL= [template urlEncodedStringFromString:[template.context stringNamed:LPMT_ARG_URL]];
    XCTAssertEqualObjects(url, encodedURL);
    
    //test for ~ sign
    url = @"http://test.com/test~end";
    template = [self createTemplateWithUrl:url];
    encodedURL= [template urlEncodedStringFromString:[template.context stringNamed:LPMT_ARG_URL]];
    XCTAssertEqualObjects(url, encodedURL);
    
    //test for _ sign
    url = @"http://test.com/test_end";
    template = [self createTemplateWithUrl:url];
    encodedURL= [template urlEncodedStringFromString:[template.context stringNamed:LPMT_ARG_URL]];
    XCTAssertEqualObjects(url, encodedURL);
    
    //test for - sign
    url = @"http://test.com/test-end";
    template = [self createTemplateWithUrl:url];
    encodedURL= [template urlEncodedStringFromString:[template.context stringNamed:LPMT_ARG_URL]];
    XCTAssertEqualObjects(url, encodedURL);
}

- (LPOpenUrlMessageTemplate *)createTemplateWithUrl:(NSString *)url {
    LPActionContext *context = [LPActionContext actionContextWithName:@"TestOpenUrl" args:@{LPMT_ARG_URL : url} messageId:0];
    LPOpenUrlMessageTemplate * template = [[LPOpenUrlMessageTemplate alloc] init];
    template.context = context;
    
    return template;
}

@end
