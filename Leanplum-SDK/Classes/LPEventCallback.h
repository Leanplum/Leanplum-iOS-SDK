//
//  LPEventCallbackManager.h
//  Leanplum
//
//  Copyright (c) 2018 Leanplum, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LPNetworkProtocol.h"

@interface LPEventCallback : NSObject

@property (nonatomic, strong) LPNetworkResponseBlock responseBlock;
@property (nonatomic, strong) LPNetworkErrorBlock errorBlock;

- (id)initWithResponseBlock:(LPNetworkResponseBlock)responseBlock
                 errorBlock:(LPNetworkErrorBlock)errorBlock;

/*
 * Invoke response callback.
 */
- (void)invokeResponseWithOperation:(id<LPNetworkOperationProtocol>)operation
                           response:(id)response;

/*
 * Invoke error callback.
 */
- (void)invokeError:(NSError *)error;

@end
