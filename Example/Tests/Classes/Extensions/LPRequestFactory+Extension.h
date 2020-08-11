//
//  LPRequestFactory+Extension.h
//  Leanplum-SDK_Tests
//
//  Created by Dejan . Krstevski on 28.07.20.
//  Copyright © 2020 Leanplum. All rights reserved.
//

#import <Leanplum/LPRequestFactory.h>

NS_ASSUME_NONNULL_BEGIN

@interface LPRequestFactory (Extension)
+ (void)swizzle_methods;
@end

NS_ASSUME_NONNULL_END
