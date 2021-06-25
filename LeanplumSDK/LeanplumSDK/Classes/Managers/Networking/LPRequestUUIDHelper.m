//
//  LPRequestUUIDHelper.m
//  Leanplum-iOS-SDK
//
//  Copyright © 2020 Leanplum. All rights reserved.
//

#import "LPRequestUUIDHelper.h"

NSString *LEANPLUM_DEFAULTS_UUID_KEY = @"__leanplum_uuid";

@implementation LPRequestUUIDHelper
+ (NSString *)generateUUID
{
    NSString *uuid = [[NSUUID UUID] UUIDString];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:uuid forKey:LEANPLUM_DEFAULTS_UUID_KEY];
    [userDefaults synchronize];
    return uuid;
}

+ (NSString *)loadUUID
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults objectForKey:LEANPLUM_DEFAULTS_UUID_KEY];
}

@end
