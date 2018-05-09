//
//  LPInternalState.m
//  Leanplum-iOS-SDK-source
//
//  Created by Mayank Sanganeria on 4/24/18.
//

#import "LPInternalState.h"

@implementation LPInternalState

+ (LPInternalState *)sharedState {
    static LPInternalState *sharedLPInternalState = nil;
    static dispatch_once_t onceLPInternalStateToken;
    dispatch_once(&onceLPInternalStateToken, ^{
        sharedLPInternalState = [[self alloc] init];
    });
    return sharedLPInternalState;
}

@end
