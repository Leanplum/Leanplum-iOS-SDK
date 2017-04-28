//File: KeychainWrapper.h
#import <UIKit/UIKit.h>

@interface LPKeychainWrapper : NSObject {}
    + (NSString *) getPasswordForUsername: (NSString *) username andServiceName: (NSString *) serviceName error: (NSError **) error;
    + (BOOL) storeUsername: (NSString *) username andPassword: (NSString *) password forServiceName: (NSString *) serviceName updateExisting: (BOOL) updateExisting error: (NSError **) error;
    + (BOOL) deleteItemForUsername: (NSString *) username andServiceName: (NSString *) serviceName error: (NSError **) error;

    + (NSData *)cipherData:(NSData *)data withKey:(NSData*)cipherKey;
    + (NSData *)decipherData:(NSData *)data withKey:(NSData*)cipherKey;
    + (NSData *)cipherString:(NSString *)data withKey:(NSString*)cipherKey;
    + (NSString *)decipherString:(NSData *)data withKey:(NSString*)cipherKey;
    
@end