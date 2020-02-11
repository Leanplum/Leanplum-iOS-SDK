//
//  LPBaseInterstitialMessageTemplateTest.m
//  Leanplum-SDK
//
//  Created by Mayank Sanganeria on 2/1/20.
//  Copyright © 2020 Leanplum. All rights reserved.
//
//  Licensed to the Apache Software Foundation (ASF) under one
//  or more contributor license agreements.  See the NOTICE file
//  distributed with this work for additional information
//  regarding copyright ownership.  The ASF licenses this file
//  to you under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing,
//  software distributed under the License is distributed on an
//  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
//  KIND, either express or implied.  See the License for the
//  specific language governing permissions and limitations
//  under the License.


#import <XCTest/XCTest.h>
#import <OHHTTPStubs/HTTPStubs.h>
#import <OHHTTPStubs/HTTPStubsPathHelpers.h>
#import "LeanplumHelper.h"
#import "LPBaseInterstitialMessageTemplate.h"

@interface LPBaseInterstitialMessageTemplate (Test)
- (UIImage *)imageFromColor:(UIColor *)color;
- (UIImage *)dismissImage:(UIColor *)color withSize:(int)size;
- (NSString *)urlEncodedStringFromString:(NSString *)urlString;

- (void)setupPopupLayout:(BOOL)isFullscreen isPushAskToAsk:(BOOL)isPushAskToAsk;
- (void)updatePopupLayout;
- (void)showPopup;

@end


@interface LPBaseInterstitialMessageTemplateTest : XCTestCase

@end

@implementation LPBaseInterstitialMessageTemplateTest

+ (void)setUp
{
    [super setUp];
    // Called only once to setup method swizzling.
    [LeanplumHelper setup_method_swizzling];
}

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
    // Clean up after every test.
    [LeanplumHelper clean_up];
    [HTTPStubs removeAllStubs];
}

- (void)test_image_from_color
{
    LPBaseInterstitialMessageTemplate *template = [[LPBaseInterstitialMessageTemplate alloc] init];
    UIImage* image = [template imageFromColor:[UIColor blueColor]];
    XCTAssertNotNil(image);
}

- (void)test_dismiss_image
{
    LPBaseInterstitialMessageTemplate *template = [[LPBaseInterstitialMessageTemplate alloc] init];
    UIImage* image = [template dismissImage:[UIColor blueColor] withSize:128];
    XCTAssertNotNil(image);
}

- (void)test_popup_setup
{
    LPBaseInterstitialMessageTemplate *template = [[LPBaseInterstitialMessageTemplate alloc] init];
    // This stub have to be removed when start command is successfully executed.
    [HTTPStubs stubRequestsPassingTest:
     ^BOOL(NSURLRequest * _Nonnull request) {
         return [request.URL.host isEqualToString:API_HOST];
     } withStubResponse:^HTTPStubsResponse * _Nonnull(NSURLRequest * _Nonnull request) {
         NSString *response_file = OHPathForFile(@"simple_start_response.json", self.class);
         return [HTTPStubsResponse responseWithFileAtPath:response_file statusCode:200
                                                    headers:@{@"Content-Type":@"application/json"}];
     }];

    XCTAssertTrue([LeanplumHelper start_development_test]);

    [template setupPopupLayout:YES isPushAskToAsk:NO];
    [template updatePopupLayout];
    [template showPopup];
    id acceptButton = [template valueForKey:@"_acceptButton"];
    XCTAssertNotNil(acceptButton);
}

- (void)test_push_popup_setup
{

    LPBaseInterstitialMessageTemplate *template = [[LPBaseInterstitialMessageTemplate alloc] init];
    // This stub have to be removed when start command is successfully executed.
    [HTTPStubs stubRequestsPassingTest:
     ^BOOL(NSURLRequest * _Nonnull request) {
         return [request.URL.host isEqualToString:API_HOST];
     } withStubResponse:^HTTPStubsResponse * _Nonnull(NSURLRequest * _Nonnull request) {
         NSString *response_file = OHPathForFile(@"simple_start_response.json", self.class);
         return [HTTPStubsResponse responseWithFileAtPath:response_file statusCode:200
                                                    headers:@{@"Content-Type":@"application/json"}];
     }];

    XCTAssertTrue([LeanplumHelper start_development_test]);

    [template setupPopupLayout:YES isPushAskToAsk:YES];
    [template updatePopupLayout];
    [template showPopup];
    id acceptButton = [template valueForKey:@"_acceptButton"];
    XCTAssertNotNil(acceptButton);
    id cancelButton = [template valueForKey:@"_cancelButton"];
    XCTAssertNotNil(cancelButton);
}

- (void)test_urlEncodedStringFromString {
    LPBaseInterstitialMessageTemplate *template = [[LPBaseInterstitialMessageTemplate alloc] init];
    XCTAssertEqualObjects([template urlEncodedStringFromString:@"http://www.leanplum.com"], @"http://www.leanplum.com");
    XCTAssertEqualObjects([template urlEncodedStringFromString:@"http://www.leanplum.com?q=simple_english1&test=2"], @"http://www.leanplum.com?q=simple_english1&test=2");
    XCTAssertEqualObjects([template urlEncodedStringFromString:@"https://ramsey.tfaforms.net/356302?id={}"], @"https://ramsey.tfaforms.net/356302?id=%7B%7D");
    XCTAssertEqualObjects([template urlEncodedStringFromString:@"lomotif://music/月亮"], @"lomotif://music/%E6%9C%88%E4%BA%AE");
}

@end
