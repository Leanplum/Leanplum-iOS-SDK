//
//  Utils.h
//  Leanplum
//
//  Copyright (c) 2018 Leanplum, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Utils : NSObject

/**
 * Checks if the object is null or empty.
 */
+ (BOOL)isNullOrEmpty:(id)obj;

/**
 * Checks if the string is empty or have spaces.
 */
+ (BOOL)isBlank:(id)obj;

/**
 * Computes MD5 of NSData. Mostly used for uploading images.
 */
+ (NSString *)md5OfData:(NSData *)data;

/**
 * Returns base64 encoded string from NSData. Convenience method
 * that supports iOS6.
 */
+ (NSString *)base64EncodedStringFromData:(NSData *)data;

/**
 * Returns unicode encoded string for supporting international
 * characters in URL
 */
+ (NSString *)urlEncodedStringFromString:(NSString *)urlString;

@end
