//
//  LPNetworkOperation.h
//  Leanplum
//
//  Created by Alexis Oyama on 11/14/16.
//  Copyright (c) 2016 Leanplum. All rights reserved.
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
