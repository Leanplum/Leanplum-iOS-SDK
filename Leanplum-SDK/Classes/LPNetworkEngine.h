//
//  LPNetworkEngine.h
//  Leanplum
//
//
//  Copyright (c) 2018 Leanplum, Inc. All rights reserved.
//

#import "LPNetworkProtocol.h"
#import "Leanplum_Reachability.h"

/**
 * Network Engine that uses NSURLSession
 */
@interface LPNetworkEngine : NSObject<LPNetworkEngineProtocol>

@property (nonatomic, strong) NSURLSessionConfiguration *sessionConfiguration;
@property (strong, nonatomic) Leanplum_Reachability *reachability;

@end
