//
//  LPFileTransferManager.m
//  LeanplumSDK-iOS
//
//  Created by Mayank Sanganeria on 2/1/19.
//  Copyright © 2019 Leanplum. All rights reserved.
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

#import "LPFileTransferManager.h"
#import "LeanplumInternal.h"
#import "LPCountAggregator.h"
#import "LPRequest.h"
#import "LPRequesting.h"
#import "LPRequestSender.h"
#import "LPRequestFactory.h"
#import "LeanplumRequest.h"
#import "LPResponse.h"
#import "LPKeychainWrapper.h"
#import "LPEventDataManager.h"
#import "LPEventCallbackManager.h"
#import "LPAPIConfig.h"

@interface LPFileTransferManager()

@property (nonatomic, strong) NSMutableDictionary *fileTransferStatus;
@property (nonatomic, strong)  NSMutableDictionary *fileUploadSize;
@property (nonatomic, strong)  NSMutableDictionary *fileUploadProgress;
@property (nonatomic, strong)  NSString *fileUploadProgressString;
@property (nonatomic, strong)  NSMutableDictionary *pendingUploads;

@end


@implementation LPFileTransferManager

+ (instancetype)sharedInstance {
    static LPFileTransferManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] init];
    });
    return sharedManager;
}

//todo: init

- (void)sendFilesNow:(NSArray *)filenames {
    RETURN_IF_TEST_MODE;
    NSMutableArray *filesToUpload = [NSMutableArray array];
    for (NSString *filename in filenames) {
        // Set state.
        if ([self.fileTransferStatus[filename] boolValue]) {
            [filesToUpload addObject:@""];
        } else {
            [filesToUpload addObject:filename];
            self.fileTransferStatus[filename] = @(YES);
            NSNumber *size = [[[NSFileManager defaultManager] attributesOfItemAtPath:filename error:nil] objectForKey:NSFileSize];
            self.fileUploadSize[filename] = size;
            self.fileUploadProgress[filename] = @0.0;
        }
    }
    if (filesToUpload.count == 0) {
        return;
    }

    // Create request.
    LPRequestFactory *reqFactory = [[LPRequestFactory alloc] initWithFeatureFlagManager:[LPFeatureFlagManager sharedManager]];
    id<LPRequesting> request = [reqFactory uploadFileWithParams:
                                @{
                                  LP_PARAM_COUNT: @(filesToUpload.count)
                                      }];
//    NSMutableDictionary *dict = [self createArgsDictionary];
//    dict[LP_PARAM_COUNT] = @(filesToUpload.count);
//    [self attachApiKeys:dict];
//    @synchronized (pendingUploads) {
//        pendingUploads[filesToUpload] = dict;
//    }
//    [self maybeSendNextUpload];
//
//    NSLog(@"Leanplum: Uploading files...");
//
//    [[LPCountAggregator sharedAggregator] incrementCount:@"send_files_now"];


}

- (void)sendDataNow:(NSData *)data forKey:(NSString *)key {
}

- (void)sendDatasNow:(NSDictionary *)datas {

}

- (void)downloadFile:(NSString *)path withCompletionHandler:(void (^__nullable)(NSError *error))completion {
    LPRequestFactory *reqFactory = [[LPRequestFactory alloc] initWithFeatureFlagManager:[LPFeatureFlagManager sharedManager]];
    id<LPRequesting> request = [reqFactory downloadFileWithParams:nil];
    [request onResponse:^(id<LPNetworkOperationProtocol> operation, id json) {
        if (completion) {
            completion(nil);
        }
    }];
    [request onError:^(NSError *error) {
        if (completion) {
            completion(error);
        }
    }];
    [[LPRequestSender sharedInstance] send:request];
}

@end
