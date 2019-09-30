//
//  LeanplumRequestTest.m
//  Leanplum-SDK_Tests
//
//  Created by Mayank Sanganeria on 4/25/19.
//  Copyright © 2019 Leanplum. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "LPFileTransferManager.h"
#import "LeanplumRequest.h"
#import "LPRequestFactory.h"
#import "LPFeatureFlagManager.h"
#import "LPNetworkOperation.h"

@interface LeanplumRequest()
- (void)downloadFile:(NSString *)path;
- (id<LPNetworkOperationProtocol>)operationForDownloadFile:(NSString *)path;
+ (NSArray *)removeIrrelevantBackgroundStartRequests:(NSArray *)requests;
@end

@interface LeanplumRequestTest : XCTestCase

@end

@implementation LeanplumRequestTest

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testDownloadFileWhenFilenameToURLsContainsURL {
    LPRequestFactory *reqFactory = [[LPRequestFactory alloc]
                                    initWithFeatureFlagManager:[LPFeatureFlagManager sharedManager]];
    LeanplumRequest *request = [reqFactory downloadFileWithParams:nil];
    NSString *path = @"file.jpg";
    NSString *urlString = @"http://www.domain.com/file.jpg";
    [LPFileTransferManager sharedInstance].filenameToURLs = @{
                                                              path : urlString
                                                              };



    LPNetworkOperation *op = (LPNetworkOperation *)[request operationForDownloadFile:path];
    XCTAssertTrue([urlString isEqualToString:[op request].URL.absoluteString]);
}

- (void)testRemoveIrrelevantBackgroundStartRequests {
    LPRequestFactory *reqFactory = [[LPRequestFactory alloc]
                                    initWithFeatureFlagManager:[LPFeatureFlagManager sharedManager]];
    LeanplumRequest *request1 = [reqFactory startWithParams:nil];
    LeanplumRequest *request2 = [reqFactory startWithParams:nil];
    LeanplumRequest *request3 = [reqFactory advanceWithParams:nil];

    NSArray *requests = @[request1, request2, request3];
    NSArray *relevantRequests = [LeanplumRequest removeIrrelevantBackgroundStartRequests:requests];

    XCTAssertTrue(relevantRequests.count == 2);
    NSArray *expectedArray = @[request1, request3];
    XCTAssertTrue([relevantRequests isEqualToArray:expectedArray]);
}


@end
