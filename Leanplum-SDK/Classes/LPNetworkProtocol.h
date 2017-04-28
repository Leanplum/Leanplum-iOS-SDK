//
//  LPNetworkProtocol.h
//  Leanplum
//
//  Created by Alexis Oyama on 11/14/16.
//  Copyright (c) 2016 Leanplum. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Leanplum_Reachability.h"

@protocol LPNetworkOperationProtocol;

/**
 * Network callback blocks.
 */
typedef void (^LPNetworkResponseBlock)(id<LPNetworkOperationProtocol> operation, id json);
typedef void (^LPNetworkResponseErrorBlock)(id<LPNetworkOperationProtocol> operation,
                                            NSError *error);
typedef void (^LPNetworkErrorBlock)(NSError *error);
typedef void (^LPNetworkProgressBlock)(double progress);

/**
 * Network Operation Protocol that all network operation have to implement.
 */
@protocol LPNetworkOperationProtocol <NSObject>

- (void)addCompletionHandler:(LPNetworkResponseBlock)response
                errorHandler:(LPNetworkResponseErrorBlock)error;
- (void)onUploadProgressChanged:(LPNetworkProgressBlock)uploadProgressBlock;

- (NSInteger)HTTPStatusCode;
- (id)responseJSON;
- (NSData *)responseData;
- (NSString*)responseString;
- (void)addFile:(NSString *)filePath forKey:(NSString *)key;
- (void)addData:(NSData *)data forKey:(NSString *)key;
- (void)cancel;
+ (NSString *)fileRequestMethod;

@end

/**
 * Network Engine Protocol that all network engine have to implement.
 */
@protocol LPNetworkEngineProtocol <NSObject>

- (id)initWithHostName:(NSString *)hostName customHeaderFields:(NSDictionary *)headers;
- (id)initWithHostName:(NSString *)hostName;

- (id<LPNetworkOperationProtocol>)operationWithPath:(NSString *)path
                                             params:(NSMutableDictionary *)body
                                         httpMethod:(NSString *)method
                                                ssl:(BOOL)useSSL
                                     timeoutSeconds:(int)timeout;
- (id<LPNetworkOperationProtocol>)operationWithURLString:(NSString *)urlString
                                                  params:(NSMutableDictionary *)body
                                              httpMethod:(NSString *)method
                                          timeoutSeconds:(int)timeout;
- (id<LPNetworkOperationProtocol>)operationWithURLString:(NSString *)urlString;
- (void)enqueueOperation:(id<LPNetworkOperationProtocol>)operation;
- (void)runSynchronously:(id<LPNetworkOperationProtocol>)operation;

@end
