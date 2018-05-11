//
//  LeanplumRequest.m
//  Leanplum
//
//  Copyright (c) 2018 Leanplum, Inc. All rights reserved.
//

#import "Leanplum.h"
#import "LeanplumInternal.h"
#import "LeanplumRequest.h"
#import "LPResponse.h"
#import "Constants.h"
#import "LPFileManager.h"
#import "NSTimer+Blocks.h"
#import "LPKeychainWrapper.h"
#import "LPEventDataManager.h"
#import "LPEventCallbackManager.h"

@implementation LPResponse

+ (NSUInteger)numResponsesInDictionary:(NSDictionary *)dictionary
{
    return [dictionary[@"response"] count];
}

+ (NSDictionary *)getResponseAt:(NSUInteger)index fromDictionary:(NSDictionary *)dictionary
{
    if (index < [LPResponse numResponsesInDictionary:dictionary]) {
        return [dictionary[@"response"] objectAtIndex:index];
    }
    return [dictionary[@"response"] lastObject];
}

+ (NSDictionary *)getLastResponse:(NSDictionary *)dictionary
{
    return [LPResponse getResponseAt:[LPResponse numResponsesInDictionary:dictionary] - 1
                      fromDictionary:dictionary];
}

+ (BOOL)isResponseSuccess:(NSDictionary *)dictionary
{
    return [dictionary[@"success"] boolValue];
}

+ (NSString *)getResponseError:(NSDictionary *)dictionary
{
    return dictionary[@"error"][@"message"];
}

@end
