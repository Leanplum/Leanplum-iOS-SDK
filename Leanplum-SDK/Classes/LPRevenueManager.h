//
//  LPRevenueManager.h
//  Leanplum iOS SDK
//
//  Created by Atanas Dobrev on 9/9/14
//  Copyright (c) 2014 Leanplum. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>


#pragma mark - LPRevenueManager interface

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
