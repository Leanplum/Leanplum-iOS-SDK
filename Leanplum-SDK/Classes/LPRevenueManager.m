//
//  LPRevenueManager.m
//  Leanplum iOS SDK
//
//  Copyright (c) 2018 Leanplum, Inc. All rights reserved.
//

#import "LPRevenueManager.h"
#import "JRSwizzle.h"
#import "LeanplumInternal.h"
#import "Constants.h"
#import "Utils.h"

#pragma mark - SKPaymentQueue(LPSKPaymentQueueExtension) implementation

void leanplum_finishTransaction(id self, SEL _cmd, SKPaymentTransaction *transaction);
void leanplum_finishTransaction(id self, SEL _cmd, SKPaymentTransaction *transaction)
{
    ((void(*)(id, SEL, SKPaymentTransaction *))LP_GET_ORIGINAL_IMP(@selector(finishTransaction:)))(self, _cmd, transaction);
    
    LP_TRY
    if (transaction.transactionState == SKPaymentTransactionStatePurchased) {
        [[LPRevenueManager sharedManager] addTransaction:transaction];
    }
    LP_END_TRY
}

#pragma mark - LPRevenueManager implementation

@implementation LPRevenueManager

#pragma mark - initialization methods

- (id)init
{
    if (self = [super init]) {
        _transactions = [[NSMutableDictionary alloc] init];
        _requests = [[NSMutableDictionary alloc] init];
        [self loadTransactions];
        // If crash happens or the os/user terminates the app and there are pending transactions.
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(saveTransactions)
                                                     name:UIApplicationWillTerminateNotification
                                                   object:nil];
    }
    return self;
}

+ (LPRevenueManager *)sharedManager
{
    static LPRevenueManager *_sharedManager = nil;
    static dispatch_once_t revenueManagerToken;
    dispatch_once(&revenueManagerToken, ^{
        _sharedManager = [[self alloc] init];
    });
    return _sharedManager;
}

#pragma mark - life cycle methods

- (void)loadTransactions
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *transactions = [defaults objectForKey:@"LPARTTransactions"];
    if (transactions) {
        for (NSString *key in transactions) {
            [self addTransactionDictionary:transactions[key]];
        }
    }
}

- (void)saveTransactions
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:_transactions forKey:@"LPARTTransactions"];
    [defaults synchronize];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - user method

- (void)trackRevenue
{
    static dispatch_once_t swizzleRevenueMethodsToken;
    dispatch_once(&swizzleRevenueMethodsToken, ^{
        [LPSwizzle swizzleInstanceMethod:@selector(finishTransaction:)
                                forClass:[SKPaymentQueue class]
                   withReplacementMethod:(IMP) leanplum_finishTransaction];
    });
}

#pragma mark - add transaction methods

- (void)addTransactionDictionary:(NSDictionary *)transaction
{
    SKProductsRequest *request = [[SKProductsRequest alloc] initWithProductIdentifiers:
                                  [NSSet setWithObjects:transaction[@"productIdentifier"], nil]];
    request.delegate = self;
    _transactions[transaction[@"transactionIdentifier"]] = transaction;
    _requests[[NSValue valueWithNonretainedObject:request]] = transaction[@"transactionIdentifier"];
    [request start];
}

- (void)addTransaction:(SKPaymentTransaction *)transaction
{
    NSData *receipt = nil;
    if ([[NSBundle mainBundle] respondsToSelector:@selector(appStoreReceiptURL)]) {
        NSURL *receiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
        receipt = [NSData dataWithContentsOfURL:receiptURL];
    } else {
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
        receipt = transaction.transactionReceipt;
#pragma GCC diagnostic pop
    }

    NSString *receiptBase64String = [Utils base64EncodedStringFromData:receipt];
    NSDictionary *transactionDictionary = @{
                                            @"transactionIdentifier":transaction.
                                            transactionIdentifier ?: [NSNull null],
                                            @"quantity":@(transaction.payment.quantity),
                                            @"productIdentifier":transaction.payment.
                                            productIdentifier,
                                            @"receiptData":receiptBase64String ?: [NSNull null]
                                            };
    [self addTransactionDictionary:transactionDictionary];
}

#pragma mark - SKProductRequest delegate methods

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
    LP_TRY
    if ([response.products count] < 1) {
        return;
    }
    NSString *transactionIdentifier = _requests[[NSValue valueWithNonretainedObject:request]];
    if (!transactionIdentifier) {
        return;
    }
    NSDictionary *transaction = _transactions[transactionIdentifier];
    if (!transaction) {
        return;
    }
    SKProduct *product = nil;
    for (SKProduct *responseProduct in response.products) {
        if ([responseProduct.productIdentifier isEqualToString:[transaction objectForKey:@"productIdentifier"]]) {
            product = responseProduct;
            break;
        }
    }
    NSString *currencyCode = [product.priceLocale objectForKey:NSLocaleCurrencyCode];

    NSString *eventName = _eventName;
    if (!eventName) {
        eventName = LP_PURCHASE_EVENT;
    }

    [Leanplum track:eventName
          withValue:[product.price doubleValue] * [transaction[@"quantity"] integerValue]
            andArgs:@{
                      LP_PARAM_CURRENCY_CODE: currencyCode,
                      @"iOSTransactionIdentifier": transaction[@"transactionIdentifier"],
                      @"iOSReceiptData": transaction[@"receiptData"],
                      @"iOSSandbox": [NSNumber numberWithBool:[LPConstantsState sharedState].isDevelopmentModeEnabled]
                      }
      andParameters:@{
                      @"item": transaction[@"productIdentifier"],
                      @"quantity": transaction[@"quantity"]
                      }];

    [_transactions removeObjectForKey:transactionIdentifier];
    [self saveTransactions];
    [_requests removeObjectForKey:[NSValue valueWithNonretainedObject:request]];
    LP_END_TRY
}

@end
