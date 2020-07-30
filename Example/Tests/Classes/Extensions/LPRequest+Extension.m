//
//  LPRequest+Extension.m
//  Leanplum-SDK_Tests
//
//  Created by Dejan . Krstevski on 28.07.20.
//  Copyright © 2020 Leanplum. All rights reserved.
//

#import "LPRequest+Extension.h"

@implementation LPRequest (Extension)
static LPNetworkResponseBlock responseCallback;

+ (void)swizzle_methods
{
    NSError *error;
    bool success = [LPSwizzle swizzleMethod:@selector(onResponse:)
    withMethod:@selector(swizzle_onResponse:)
         error:&error
         class:[LPRequest class]];
    
    if (!success || error) {
           NSLog(@"Failed swizzling methods for LPRequest: %@", error);
       }
}

- (void)swizzle_onResponse:(LPNetworkResponseBlock) response_
{
    [self swizzle_onResponse:^(id<LPNetworkOperationProtocol> operation, id json) {
        if (responseCallback) {
            responseCallback(operation, json);
            responseCallback = nil;
        }
        response_(operation, json);
    }];
}

+ (void)validate_onResponse:(LPNetworkResponseBlock)callback
{
    responseCallback = callback;
}

+ (void)reset
{
    responseCallback = nil;
}

@end
