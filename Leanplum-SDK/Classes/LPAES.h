//
//  LPAES.h
//  Leanplum
//
//  Created by Alexis Oyama on 4/25/17.
//  Copyright (c) 2017 Leanplum. All rights reserved.
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
