//
//  LPRequestFactory+Extension.m
//  Leanplum-SDK_Tests
//
//  Created by Dejan . Krstevski on 28.07.20.
//  Copyright © 2020 Leanplum. All rights reserved.
//

#import "LPRequestFactory+Extension.h"
#import "LPRequestSender+Categories.h"

@implementation LPRequestFactory (Extension)

+ (void)swizzle_methods
{
    NSError *error;
    bool success = [LPSwizzle swizzleClassMethod:@selector(createGetForApiMethod:params:)
                    withClassMethod:@selector(swizzle_createGetForApiMethod:params:)
                                       error:&error
                                       class:[LPRequestFactory class]];
    success &= [LPSwizzle swizzleClassMethod:@selector(createPostForApiMethod:params:)
                             withClassMethod:@selector(swizzle_createPostForApiMethod:params:)
                                       error:&error
                                       class:[LPRequestFactory class]];
    if (!success || error) {
        NSLog(@"Failed swizzling methods for LPRequestFactory: %@", error);
    }
}

+ (LPRequest *)swizzle_createGetForApiMethod:(NSString *) apiMethod_ params:(NSDictionary *) params_
{
    if ([LPRequestSender sharedInstance].requestCallback != nil)
    {
        BOOL success = [LPRequestSender sharedInstance].requestCallback(@"get", apiMethod_, params_);
        if (success) {
            [LPRequestSender sharedInstance].requestCallback = nil;
        }
    }
    return [self swizzle_createGetForApiMethod:apiMethod_ params:params_];
}

+ (LPRequest *)swizzle_createPostForApiMethod:(NSString *) apiMethod_ params:(NSDictionary *) params_
{
    if ([LPRequestSender sharedInstance].requestCallback != nil)
    {
        BOOL success = [LPRequestSender sharedInstance].requestCallback(@"post", apiMethod_, params_);
        if (success) {
            [LPRequestSender sharedInstance].requestCallback = nil;
        }
    }
    return [self swizzle_createPostForApiMethod:apiMethod_ params:params_];
}

@end
