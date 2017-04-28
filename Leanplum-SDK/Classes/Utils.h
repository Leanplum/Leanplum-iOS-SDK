//
//  Utils.h
//  Leanplum
//
//  Created by Ben Marten on 6/6/16.
//  Copyright (c) 2016 Leanplum. All rights reserved.
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

@end
