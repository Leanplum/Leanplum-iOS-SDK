//
//  LPEventCallbackManager.m
//  Leanplum
//
//  Copyright (c) 2018 Leanplum, Inc. All rights reserved.
//

#import "LPEventCallback.h"
#import "LeanplumRequest.h"
#import "LPResponse.h"

@implementation LPEventCallback

- (id)initWithResponseBlock:(LPNetworkResponseBlock)responseBlock
                 errorBlock:(LPNetworkErrorBlock)errorBlock
{
    if (self = [super init]) {
        self.responseBlock = [responseBlock copy];
        self.errorBlock = [errorBlock copy];
    }
    return self;
}

- (void)invokeResponseWithOperation:(id<LPNetworkOperationProtocol>)operation
                           response:(id)response
{
    if (!self.responseBlock) {
        return;
    }
    
    // Ensure all callbacks are on main thread.
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.responseBlock(operation, response);
        });
        return;
    }

    self.responseBlock(operation, response);
}

- (void)invokeError:(NSError *)error
{
    if (!self.errorBlock) {
        return;
    }
    
    // Ensure all callbacks are on main thread.
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.errorBlock(error);
        });
        return;
    }
    
    self.errorBlock(error);
}

@end
