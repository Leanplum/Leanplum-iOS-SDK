//
//  LPNetworkEngine.h
//  Leanplum
//
//  Created by Alexis Oyama on 11/14/16.
//  Copyright (c) 2016 Leanplum. All rights reserved.
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
