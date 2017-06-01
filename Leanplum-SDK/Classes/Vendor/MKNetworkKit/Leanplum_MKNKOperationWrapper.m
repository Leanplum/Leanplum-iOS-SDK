//
//  Leanplum_MKNKOperationWrapper.m
//  Leanplum
//
//  Created by Alexis Oyama on 11/14/16.
//  Copyright (c) 2016 Leanplum, Inc. All rights reserved.
//
#import <Foundation/Foundation.h>

#if __IPHONE_OS_VERSION_MIN_REQUIRED < 70000

#import "Leanplum_MKNKOperationWrapper.h"

@implementation Leanplum_MKNKOperationWrapper

- (id)init {
    self = [super init];
    self.operation = [Leanplum_MKNetworkOperation new];
    return self;
}

- (void)addCompletionHandler:(LPNetworkResponseBlock)responseHandler
                errorHandler:(LPNetworkResponseErrorBlock)errorHandler
{
    [self.operation addCompletionHandler:^(Leanplum_MKNetworkOperation *completedOperation) {
        if (responseHandler) {
            Leanplum_MKNKOperationWrapper *op = [Leanplum_MKNKOperationWrapper new];
            op.operation = completedOperation;
            responseHandler(op, self.operation.responseJSON);
        }
    } errorHandler:^(Leanplum_MKNetworkOperation *completedOperation, NSError *error) {
        if (errorHandler) {
            Leanplum_MKNKOperationWrapper *op = [Leanplum_MKNKOperationWrapper new];
            op.operation = completedOperation;
            errorHandler(op, error);
        }
    }];
}

- (void)onUploadProgressChanged:(LPNetworkProgressBlock)uploadProgressBlock
{
    [self.operation onUploadProgressChanged:^(double progress) {
        if (uploadProgressBlock) {
            uploadProgressBlock(progress);
        }
    }];
}

- (NSInteger)HTTPStatusCode
{
    return self.operation.HTTPStatusCode;
}

- (id)responseJSON
{
    return self.operation.responseJSON;
}

- (NSData *)responseData
{
    return self.operation.responseData;
}

- (NSString*)responseString
{
    return self.operation.responseString;
}

- (void)addFile:(NSString *)filePath forKey:(NSString *)key
{
    [self.operation addFile:filePath forKey:key];
}

- (void)addData:(NSData *)data forKey:(NSString *)key
{
    [self.operation addData:data forKey:key];
}

- (void)cancel
{
    [self.operation cancel];
}

+ (NSString *)fileRequestMethod;
{
    return @"GET";
}

@end

#endif
