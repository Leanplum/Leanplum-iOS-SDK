//
//  Utils.m
//  Leanplum
//
//  Created by Ben Marten on 6/6/16.
//  Copyright (c) 2016 Leanplum. All rights reserved.
//

#import "Utils.h"
#import <CommonCrypto/CommonDigest.h>

@implementation Utils

+ (BOOL)isNullOrEmpty:(id)obj
{
    return obj == nil
        || ([obj respondsToSelector:@selector(length)] && [(NSData *)obj length] == 0)
        || ([obj respondsToSelector:@selector(count)] && [(NSArray *)obj count] == 0);
}

+ (BOOL)isBlank:(NSString *)str
{
    return [[str stringByTrimmingCharactersInSet:
             [NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@""];
}

+ (NSString *)md5OfData:(NSData *)data
{
    if ([Utils isNullOrEmpty:data]) {
        return @"";
    }

    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5(data.bytes, (CC_LONG)data.length, digest);
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH*2];
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [output appendFormat:@"%02x", digest[i]];
    }
    return output;
}

+ (NSString *)base64EncodedStringFromData:(NSData *)data
{
    if ([data respondsToSelector:
         @selector(base64EncodedStringWithOptions:)]) {
        return [data base64EncodedStringWithOptions:0];
    }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    return [data base64Encoding];
#pragma clang diagnostic pop

}

@end
