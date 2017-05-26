//
//  Leanplum_MKNKOperationWrapper.h
//  Leanplum
//
//  Created by Alexis Oyama on 11/14/16.
//  Copyright (c) 2016 Leanplum, Inc. All rights reserved.
//
#import "LPNetworkProtocol.h"
#import "MKNetworkKit.h"

#if __IPHONE_OS_VERSION_MIN_REQUIRED < 70000

/**
 * Wrapper for Leanplum_MKNetworkOperation to use with the factory.
 */
@interface Leanplum_MKNKOperationWrapper : NSObject<LPNetworkOperationProtocol>

@property (nonatomic, strong) Leanplum_MKNetworkOperation *operation;

@end

#endif
