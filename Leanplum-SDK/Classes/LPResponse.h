//
//  LeanplumRequest.h
//  Leanplum
//
//  Copyright (c) 2018 Leanplum, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Leanplum.h"
#import "LPNetworkFactory.h"

@interface LPResponse : NSObject

+ (NSUInteger)numResponsesInDictionary:(NSDictionary *)dictionary;
+ (NSDictionary *)getResponseAt:(NSUInteger)index fromDictionary:(NSDictionary *)dictionary;
+ (NSDictionary *)getLastResponse:(NSDictionary *)dictionary;
+ (BOOL)isResponseSuccess:(NSDictionary *)dictionary;
+ (NSString *)getResponseError:(NSDictionary *)dictionary;

@end
