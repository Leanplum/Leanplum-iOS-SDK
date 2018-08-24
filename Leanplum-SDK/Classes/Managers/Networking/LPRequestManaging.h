//
//  LPRequestManaging.h
//  Pods
//
//  Created by Mayank Sanganeria on 8/23/18.
//

#ifndef LPRequestManaging_h
#define LPRequestManaging_h

#import "Leanplum.h"
#import "LPNetworkFactory.h"
#import "LPRequesting.h"

@protocol LPRequestManaging

@property (nonatomic, readonly) NSString *appId;
@property (nonatomic, strong) NSString *deviceId;
@property (nonatomic, strong) NSString *userId;
@property (nonatomic, strong) NSString *token;
@property (nonatomic, strong) NSDictionary *requestHeaders;

- (void)setAppId:(NSString *)appId withAccessKey:(NSString *)accessKey;

- (void)loadToken;
- (void)saveToken;

- (NSDictionary *)createHeaders;
- (NSMutableDictionary *)createArgsDictionaryForRequest:(id<LPRequesting>)request;
- (void)attachApiKeys:(NSMutableDictionary *)dict;

// Files transfer
@property (nonatomic, strong) NSString *uploadUrl;

- (void)sendRequest:(id<LPRequesting>)request;
- (void)sendNowRequest:(id<LPRequesting>)request;
- (void)sendEventuallyRequest:(id<LPRequesting>)request;
- (void)sendIfConnectedRequest:(id<LPRequesting>)request;;
- (void)sendIfConnectedSync:(BOOL)sync request:(id<LPRequesting>)request;
// Sends the request if another request hasn't been sent within a particular time delay.
- (void)sendIfDelayedRequest:(id<LPRequesting>)request;

/**
 * Sends one data. Uses sendDatasNow: internally. See this method for more information.
 */
- (void)sendDataNow:(NSData *)data forKey:(NSString *)key request:(id<LPRequesting>)request;

/**
 * Send datas where key is the name and object is the data.
 * For example, key can be "file0" and object is NSData of png.
 */
- (void)sendDatasNow:(NSDictionary *)datas request:(id<LPRequesting>)request;

@end

#endif /* LPRequestManaging_h */
