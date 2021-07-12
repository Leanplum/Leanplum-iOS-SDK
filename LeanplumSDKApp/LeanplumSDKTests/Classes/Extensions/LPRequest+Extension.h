//
//  LPRequest+Extension.h
//  Leanplum-SDK_Tests
//
//  Created by Dejan Krstevski on 28.07.20.
//  Copyright © 2020 Leanplum. All rights reserved.
//

#import <Leanplum/LPRequest.h>

NS_ASSUME_NONNULL_BEGIN

@interface LPRequest (Extension)
+ (void)validate_onResponse:(LPNetworkResponseBlock)response;
+ (void)swizzle_methods;
+ (void)reset;
@end

NS_ASSUME_NONNULL_END
