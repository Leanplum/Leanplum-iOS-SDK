//
//  LPEventCallbackManager.m
//  Pods
//
//  Created by Alexis Oyama on 7/11/17.
//
//

#import "LPEventCallbackManager.h"
#import "LeanplumRequest.h"

@implementation LPEventCallback

- (id)initWithResponseBlock:(LPNetworkResponseBlock)responseBlock
                 errorBlock:(LPNetworkErrorBlock)errorBlock
{
    if (self = [super init]) {
        self.responseBlock = [responseBlock copy];
        self.errorBlock = [errorBlock copy];
    }
    return self;
}

- (void)invokeResponseWithOperation:(id<LPNetworkOperationProtocol>)operation
                           response:(id)response
{
    if (self.responseBlock) {
        self.responseBlock(operation, response);
    }
}

- (void)invokeError:(NSError *)error
{
    if (self.errorBlock) {
        self.errorBlock(error);
    }
}

@end

@implementation LPEventCallbackManager

+ (NSMutableDictionary *)eventCallbackMap
{
    static NSMutableDictionary *_eventCallbackMap;
    static dispatch_once_t eventCallbackMapToken;
    dispatch_once(&eventCallbackMapToken, ^{
        _eventCallbackMap = [NSMutableDictionary new];
    });
    return _eventCallbackMap;
}

+ (void)addEventCallbackAt:(NSInteger)index
                 onSuccess:(LPNetworkResponseBlock)responseBlock
                   onError:(LPNetworkErrorBlock)errorBlock
{
    if (!responseBlock && !errorBlock) {
        return;
    }
    
    NSMutableDictionary *callbackMap = [LPEventCallbackManager eventCallbackMap];
    LPEventCallback *callback = [[LPEventCallback alloc] initWithResponseBlock:responseBlock
                                                                    errorBlock:errorBlock];
    callbackMap[@(index)] = callback;
}

+ (void)invokeSuccessCallbacksOnResponses:(id)responses
                                 requests:(NSArray *)requests
                                operation:(id<LPNetworkOperationProtocol>)operation
{
    // Invoke and remove the callbacks that have errors.
    [LPEventCallbackManager invokeErrorCallbacksOnResponses:responses];
    
    NSMutableDictionary *callbackMap = [LPEventCallbackManager eventCallbackMap];
    NSMutableDictionary *updatedCallbackMap = [NSMutableDictionary new];
    NSMutableDictionary *activeResponseMap = [NSMutableDictionary new];
    
    for (NSNumber *indexObject in callbackMap.allKeys) {
        NSInteger index = [indexObject integerValue];
        LPEventCallback *eventCallback = callbackMap[indexObject];
        
        // If index is in range, execute and remove it.
        // If not, requests are in the future. Update the index.
        [callbackMap removeObjectForKey:indexObject];
        if (index >= requests.count) {
            index -= requests.count;
            updatedCallbackMap[@(index)] = eventCallback;
        } else if (eventCallback.responseBlock) {
            activeResponseMap[indexObject] = [eventCallback.responseBlock copy];
        }
    }
    [callbackMap addEntriesFromDictionary:updatedCallbackMap];
    
    // Execute responses afterwards to prevent index collision.
    [activeResponseMap enumerateKeysAndObjectsUsingBlock:^(NSNumber *indexObject, LPNetworkResponseBlock responseBlock, BOOL *stop) {
        NSInteger index = [indexObject integerValue];
        id response = [LPResponse getResponseAt:index fromDictionary:responses];
        responseBlock(operation, response);
    }];
}

+ (void)invokeErrorCallbacksOnResponses:(id)responses
{
    // Handle errors that don't return an HTTP error code.
    NSMutableDictionary *callbackMap = [LPEventCallbackManager eventCallbackMap];
    for (NSUInteger i = 0; i < [LPResponse numResponsesInDictionary:responses]; i++) {
        NSDictionary *response = [LPResponse getResponseAt:i fromDictionary:responses];
        if ([LPResponse isResponseSuccess:response]) {
            continue;
        }
        
        NSString *errorMessage = @"API error";
        NSString *responseError = [LPResponse getResponseError:response];
        if (responseError) {
            errorMessage = [NSString stringWithFormat:@"API error: %@", errorMessage];
        }
        NSLog(@"Leanplum: %@", errorMessage);
        
        LPEventCallback *callback = callbackMap[@(i)];
        if (callback) {
            [callbackMap removeObjectForKey:@(i)];
            NSError *error = [NSError errorWithDomain:@"Leanplum" code:2
                                             userInfo:@{NSLocalizedDescriptionKey: errorMessage}];
            [callback invokeError:error];
        }
    }
}

+ (void)invokeErrorCallbacksWithError:(NSError *)error
{
    NSMutableDictionary *callbackMap = [LPEventCallbackManager eventCallbackMap];
    for (LPEventCallback *callback in callbackMap) {
        [callback invokeError:error];
    }
    [callbackMap removeAllObjects];
}

@end
