//
//  LPEventCallbackManager.h
//  Pods
//
//  Created by Alexis Oyama on 7/11/17.
//
//

#import <Foundation/Foundation.h>
#import "LPNetworkProtocol.h"

@interface LPEventCallback : NSObject

@property (nonatomic, strong) LPNetworkResponseBlock responseBlock;
@property (nonatomic, strong) LPNetworkErrorBlock errorBlock;

- (id)initWithResponseBlock:(LPNetworkResponseBlock)responseBlock
                 errorBlock:(LPNetworkErrorBlock)errorBlock;

/*
 * Invoke response callback.
 */
- (void)invokeResponseWithOperation:(id<LPNetworkOperationProtocol>)operation
                           response:(id)response;

/*
 * Invoke error callback.
 */
- (void)invokeError:(NSError *)error;

@end

@interface LPEventCallbackManager : NSObject

/**
 * Returns dictionary that maps event index to event callback object.
 * Since requests are batched there can be a case where other LeanplumRequest
 * can take future LeanplumRequest events. We need to ensure all callbacks are
 * called from any instance.
 */
+ (NSMutableDictionary *)eventCallbackMap;

+ (void)addEventCallbackAt:(NSInteger)index
           onSuccess:(LPNetworkResponseBlock)responseBlock
             onError:(LPNetworkErrorBlock)errorBlock;

/** 
 * Invoke success callbacks that within the range.
 * Note we need to do this because Request can steal future sendNow callbacks.
 * Callback map will either have to be updated or removed.
 */
+ (void)invokeSuccessCallbacksOnResponses:(id)responses
                                 requests:(NSArray *)requests
                                operation:(id<LPNetworkOperationProtocol>)operation;

/**
 * Invoke error callbacks if responses does not contain 'success'.
 * Called internally from invokeSuccessCallbacksOnResponses:.
 */
+ (void)invokeErrorCallbacksOnResponses:(id)responses;

/**
 * Invoke all success callbacks. Loop through all the possible callbacks.
 * Note we need to do this because Request can steal future sendNow callbacks.
 * Callback map will either have to be updated or removed.
 */
+ (void)invokeErrorCallbacksWithError:(NSError *)error;

@end
