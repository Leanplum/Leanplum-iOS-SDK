//
//  LPNetworkOperation.h
//  Leanplum
//
//  Copyright (c) 2018 Leanplum, Inc. All rights reserved.
//

#import "LPNetworkProtocol.h"

/**
 * Network Operation
 * Uses session task to submit requests.
 */
@interface LPNetworkOperation : NSObject<LPNetworkOperationProtocol, NSURLSessionTaskDelegate>

@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSURLSessionTask *task;
@property (nonatomic, strong) NSMutableURLRequest *request;
@property (nonatomic, strong) NSDictionary *requestParam;

/**
 * Initializer that requires to build the requests.
 */
- (id)initWithSessionConfiguration:(NSURLSessionConfiguration *)configuration
                           request:(NSMutableURLRequest *)request
                             param:(NSDictionary *)param;

/**
 * Sends the request.
 */
- (void)run;
- (void)runSynchronously:(BOOL)synchronous;

@end
