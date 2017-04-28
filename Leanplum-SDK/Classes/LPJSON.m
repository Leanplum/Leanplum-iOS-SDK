//
//  LPJSON.m
//  Leanplum
//
//  Created by Alexis Oyama on 2/1/17.
//  Copyright (c) 2017 Leanplum. All rights reserved.
//

#import "LPJSON.h"
#import "LeanplumInternal.h"

@implementation LPJSON

+ (NSString *)stringFromJSON : (id)object
{
    if (![NSJSONSerialization isValidJSONObject:object]) {
        return nil;
    }
    NSError *error;
    NSData *data = [NSJSONSerialization dataWithJSONObject:object options:0
                                                     error:&error];
    if (error) {
        return nil;
    }
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

+ (id)JSONFromString : (NSString *)string
{
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    return [LPJSON JSONFromData:data];
}

+ (id)JSONFromData: (NSData *)data
{
    if (!data) {
        return nil;
    }

    NSError *error;
    id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    if (error) {
        return nil;
    }
    return json;
}

@end
