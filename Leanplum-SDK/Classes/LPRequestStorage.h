//
//  LPRequestStorage.h
//  Leanplum
//
//  Copyright (c) 2018 Leanplum, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * Request Storage is deprecated from 2.0.2.
 * Use LPEventDataManager instead. 
 * Do not use this class other than migrating.
 */
@interface LPRequestStorage : NSObject {
    @private
    NSTimeInterval _lastSentTime;
}

@property (nonatomic, readonly) NSTimeInterval lastSentTime;

+ (LPRequestStorage *)sharedStorage;

/**
 * Push request to file by read, append, and then write.
 */
- (void)pushRequest:(NSDictionary *)requestData;

/**
 * Push multiple requests to file by read, append, and then write.
 */
- (void)pushRequests:(NSArray *)requestDatas;

/**
 * Read all requests and delete the file.
 */
- (NSArray *)popAllRequests;

/**
 * This file path returns the one in documents directory. Requests should be stored here.
 */
- (NSString *)documentsFilePath;

@end
