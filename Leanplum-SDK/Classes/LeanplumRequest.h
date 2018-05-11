//
//  LeanplumRequest.h
//  Leanplum
//
//  Copyright (c) 2018 Leanplum, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Leanplum.h"
#import "LPNetworkFactory.h"

@interface LeanplumRequest : NSObject {
@private
    NSString *_httpMethod;
    NSString *_apiMethod;
    NSDictionary *_params;
    LPNetworkResponseBlock _response;
    LPNetworkErrorBlock _error;
    BOOL _sent;
}

+ (void)setAppId:(NSString *)appId withAccessKey:(NSString *)accessKey;
+ (void)setDeviceId:(NSString *)deviceId;
+ (void)setUserId:(NSString *)userId;
+ (void)setUploadUrl:(NSString *)url;

+ (NSString *)deviceId;
+ (NSString *)userId;
+ (void)setToken:(NSString *)token;
+ (void)loadToken;
+ (void)saveToken;

+ (NSString *)appId;
+ (NSString *)token;

- (void)attachApiKeys:(NSMutableDictionary *)dict;

- (id)initWithHttpMethod:(NSString *)httpMethod apiMethod:(NSString *)apiMethod
    params:(NSDictionary *)params;

+ (LeanplumRequest *)get:(NSString *)apiMethod params:(NSDictionary *)params;
+ (LeanplumRequest *)post:(NSString *)apiMethod params:(NSDictionary *)params;

- (void)onResponse:(LPNetworkResponseBlock)response;
- (void)onError:(LPNetworkErrorBlock)error;

- (void)send;
- (void)sendNow;
- (void)sendEventually;
- (void)sendIfConnected;
- (void)sendIfConnectedSync:(BOOL)sync;
// Sends the request if another request hasn't been sent within a particular time delay.
- (void)sendIfDelayed;
- (void)sendFilesNow:(NSArray *)filenames;

/**
 * Sends one data. Uses sendDatasNow: internally. See this method for more information.
 */
- (void)sendDataNow:(NSData *)data forKey:(NSString *)key;

/**
 * Send datas where key is the name and object is the data.
 * For example, key can be "file0" and object is NSData of png.
 */
- (void)sendDatasNow:(NSDictionary *)datas;

- (void)downloadFile:(NSString *)path;

+ (int)numPendingDownloads;
+ (void)onNoPendingDownloads:(LeanplumVariablesChangedBlock)block;

@end
