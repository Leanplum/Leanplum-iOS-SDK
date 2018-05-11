//
//  LPAES.h
//  Leanplum
//
//  Copyright (c) 2018 Leanplum, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LPAES : NSObject

/**
 * Returns AES128 encrypted data using the crypto framework.
 */
+ (NSData *)encryptedDataFromData:(NSData *)data;

/**
 * Returns AES128 decrypted data using the crypto framework.
 */
+ (NSData *)decryptedDataFromData:(NSData *)data;

@end
