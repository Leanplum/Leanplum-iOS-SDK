//
//  LPRevenueManager.h
//  Leanplum iOS SDK
//
//  Copyright (c) 2018 Leanplum, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

@interface LPRevenueManager : NSObject <SKProductsRequestDelegate>
{
    NSMutableDictionary *_transactions;
    NSMutableDictionary *_requests;
}

+ (LPRevenueManager *)sharedManager;
- (void)trackRevenue;
- (void)addTransaction:(SKPaymentTransaction *)transaction;

@property (nonatomic, copy) NSString *eventName;

@end
