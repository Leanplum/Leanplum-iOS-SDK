//
//  LPRequesting.h
//  Pods
//
//  Created by Mayank Sanganeria on 8/23/18.
//

#ifndef LPRequesting_h
#define LPRequesting_h

#import "LPNetworkProtocol.h"
#import "LeanplumInternal.h"

@protocol LPRequesting

@property (nonatomic, strong) NSString *apiMethod;
@property (nonatomic, strong) NSDictionary *params;
@property (atomic) BOOL sent;
@property (nonatomic, copy) LPNetworkResponseBlock responseBlock;
@property (nonatomic, copy) LPNetworkErrorBlock errorBlock;

- (void)onResponse:(LPNetworkResponseBlock)response;
- (void)onError:(LPNetworkErrorBlock)error;

@end

#endif /* LPRequesting_h */
