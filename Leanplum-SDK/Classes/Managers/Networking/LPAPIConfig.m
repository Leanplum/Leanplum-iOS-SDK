//
//  LPAPIConfig.m
//  Leanplum-iOS-SDK-source
//
//  Created by Mayank Sanganeria on 8/25/18.
//

#import "LPAPIConfig.h"
#import "LeanplumInternal.h"
#import "LPResponse.h"
#import "LPKeychainWrapper.h"
#import "LPEventDataManager.h"
#import "LPEventCallbackManager.h"

@interface LPAPIConfig()

@property (nonatomic, strong) NSString *appId;
@property (nonatomic, strong) NSString *accessKey;

@end


@implementation LPAPIConfig

+ (instancetype)sharedConfig {
    static LPAPIConfig *sharedConfig = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedConfig = [[self alloc] init];
        sharedConfig.token = nil;
    });
    return sharedConfig;
}

- (void)setAppId:(NSString *)appId withAccessKey:(NSString *)accessKey
{
    self.appId = appId;
    self.accessKey = accessKey;
}

- (void)loadToken
{
    NSError *err;
    NSString *token_ = [LPKeychainWrapper getPasswordForUsername:LP_KEYCHAIN_USERNAME
                                                  andServiceName:LP_KEYCHAIN_SERVICE_NAME
                                                           error:&err];
    if (!token_) {
        return;
    }

    [self setToken:token_];
}

- (void)saveToken
{
    NSError *err;
    [LPKeychainWrapper storeUsername:LP_KEYCHAIN_USERNAME
                         andPassword:[self token]
                      forServiceName:LP_KEYCHAIN_SERVICE_NAME
                      updateExisting:YES
                               error:&err];
}

@end
