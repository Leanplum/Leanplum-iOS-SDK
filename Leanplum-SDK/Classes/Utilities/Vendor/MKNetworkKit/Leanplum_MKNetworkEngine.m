//
//  MKNetworkEngine.m
//  MKNetworkKit
//
//  Created by Mugunth Kumar (@mugunthkumar) on 11/11/11.
//  Copyright (C) 2011-2020 by Steinlogic

//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
#import <Foundation/Foundation.h>

#if __IPHONE_OS_VERSION_MIN_REQUIRED < 70000

#import "MKNetworkKit.h"
#import "LPConstants.h"

#define kFreezableOperationExtension @"mknetworkkitfrozenoperation"

#ifdef __OBJC_GC__
#error MKNetworkKit does not support Objective-C Garbage Collection
#endif

#if ! __has_feature(objc_arc)
#error MKNetworkKit is ARC only. Either turn on ARC for the project or use -fobjc-arc flag
#endif

@interface Leanplum_MKNetworkEngine (/*Private Methods*/)

@property (strong, nonatomic) NSString *hostName;
@property (strong, nonatomic) Leanplum_Reachability *reachability;
@property (strong, nonatomic) NSDictionary *customHeaders;
@property (assign, nonatomic) Class customOperationSubclass;

@property (nonatomic, strong) NSMutableDictionary *memoryCache;
@property (nonatomic, strong) NSMutableArray *memoryCacheKeys;
@property (nonatomic, strong) NSMutableDictionary *cacheInvalidationParams;

@end

static NSOperationQueue *_sharedNetworkQueue;

@implementation Leanplum_MKNetworkEngine

// Network Queue is a shared singleton object.
// no matter how many instances of MKNetworkEngine is created, there is one and only one network queue
// In theory an app should contain as many network engines as the number of domains it talks to

#pragma mark -
#pragma mark Initialization

+(void) initialize {
  
  if(!_sharedNetworkQueue) {
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
      _sharedNetworkQueue = [[NSOperationQueue alloc] init];
      [_sharedNetworkQueue addObserver:[self self] forKeyPath:@"operationCount" options:0 context:NULL];
      [_sharedNetworkQueue setMaxConcurrentOperationCount:6];
      
    });
  }            
}

- (id) initWithHostName:(NSString*) hostName {
  
  return [self initWithHostName:hostName apiPath:nil customHeaderFields:nil];
}

- (id) initWithHostName:(NSString*) hostName apiPath:(NSString*) apiPath customHeaderFields:(NSDictionary*) headers {
  
  if((self = [super init])) {        
    
    self.apiPath = apiPath;

    if(hostName) {
      [[NSNotificationCenter defaultCenter] addObserver:self 
                                               selector:@selector(reachabilityChanged:) 
                                                   name:kLeanplumReachabilityChangedNotification
                                                 object:nil];
      
      self.hostName = hostName;  
      self.reachability = [Leanplum_Reachability reachabilityWithHostname:self.hostName];
      [self.reachability startNotifier];            
    }
    
    if(headers[@"User-Agent"] == nil) {
      
      NSMutableDictionary *newHeadersDict = [headers mutableCopy];
      NSString *userAgentString = [NSString stringWithFormat:@"%@/%@", 
                                   NSBundle.mainBundle.infoDictionary[(NSString *)kCFBundleNameKey],
                                   NSBundle.mainBundle.infoDictionary[(NSString *)kCFBundleVersionKey]];
      newHeadersDict[@"User-Agent"] = userAgentString;
      self.customHeaders = newHeadersDict;
    } else {
      self.customHeaders = headers;
    }    
    
    self.customOperationSubclass = [Leanplum_MKNetworkOperation class];
  }
  
  return self;  
}

- (id) initWithHostName:(NSString*) hostName customHeaderFields:(NSDictionary*) headers {
  
  return [self initWithHostName:hostName apiPath:nil customHeaderFields:headers];
}

#pragma mark -
#pragma mark Memory Mangement

-(void) dealloc {
  
  [[NSNotificationCenter defaultCenter] removeObserver:self name:kLeanplumReachabilityChangedNotification object:nil];
#if TARGET_OS_IPHONE    
  [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
#endif
}

+(void) dealloc {
  
  [_sharedNetworkQueue removeObserver:[self self] forKeyPath:@"operationCount"];
}

#pragma mark -
#pragma mark KVO for network Queue

+ (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object 
                         change:(NSDictionary *)change context:(void *)context
{
  if (object == _sharedNetworkQueue && [keyPath isEqualToString:@"operationCount"]) {
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kMKNetworkEngineOperationCountChanged 
                                                        object:[NSNumber numberWithInteger:[_sharedNetworkQueue operationCount]]];
#if LP_NOT_TV
      if ([LPConstantsState sharedState].networkActivityIndicatorEnabled) {
          [UIApplication sharedApplication].networkActivityIndicatorVisible =
          ([_sharedNetworkQueue.operations count] > 0);
      }
#endif
  }
  else {
    [super observeValueForKeyPath:keyPath ofObject:object 
                           change:change context:context];
  }
}

#pragma mark -
#pragma mark Reachability related

-(void) reachabilityChanged:(NSNotification*) notification
{
  if([self.reachability currentReachabilityStatus] == ReachableViaWiFi)
  {
    DLog(@"Server [%@] is reachable via Wifi", self.hostName);
    [_sharedNetworkQueue setMaxConcurrentOperationCount:6];
  }
  else if([self.reachability currentReachabilityStatus] == ReachableViaWWAN)
  {
    DLog(@"Server [%@] is reachable only via cellular data", self.hostName);
    [_sharedNetworkQueue setMaxConcurrentOperationCount:2];
  }
  else if([self.reachability currentReachabilityStatus] == NotReachable)
  {
    DLog(@"Server [%@] is not reachable", self.hostName);
  }   
  
  if(self.reachabilityChangedHandler) {
    self.reachabilityChangedHandler([self.reachability currentReachabilityStatus]);
  }
}

#pragma mark Freezing operations (Called when network connectivity fails)

-(NSString*) readonlyHostName {
  
  return [_hostName copy];
}

-(BOOL) isReachable {
  
  return ([self.reachability currentReachabilityStatus] != NotReachable);
}

#pragma mark -
#pragma mark Create methods

-(void) registerOperationSubclass:(Class) aClass {
  
  self.customOperationSubclass = aClass;
}

-(Leanplum_MKNetworkOperation*) operationWithPath:(NSString*) path {
  
  return [self operationWithPath:path params:nil];
}

-(Leanplum_MKNetworkOperation*) operationWithPath:(NSString*) path
                                  params:(NSMutableDictionary*) body {
  
  return [self operationWithPath:path 
                          params:body 
                      httpMethod:@"GET"];
}

-(Leanplum_MKNetworkOperation*) operationWithPath:(NSString*) path
                                  params:(NSMutableDictionary*) body
                              httpMethod:(NSString*)method  {
  
  return [self operationWithPath:path
                          params:body
                      httpMethod:method
                             ssl:NO
                  timeoutSeconds:[LPConstantsState sharedState].networkTimeoutSeconds];
}

-(Leanplum_MKNetworkOperation*) operationWithPath:(NSString*) path
                                  params:(NSMutableDictionary*) body
                              httpMethod:(NSString*)method 
                                     ssl:(BOOL) useSSL {
    return [self operationWithPath:path
                            params:body
                        httpMethod:method
                               ssl:useSSL
                    timeoutSeconds:[LPConstantsState sharedState].networkTimeoutSeconds];

}

-(Leanplum_MKNetworkOperation*) operationWithPath:(NSString*) path
                                           params:(NSMutableDictionary*) body
                                       httpMethod:(NSString*)method
                                              ssl:(BOOL) useSSL
                                   timeoutSeconds:(int)timeout {
    
    if(self.hostName == nil) {
        
        DLog(@"Hostname is nil, use operationWithURLString: method to create absolute URL operations");
        return nil;
    }
    
    NSMutableString *urlString = [NSMutableString stringWithFormat:@"%@://%@", useSSL ? @"https" : @"http", self.hostName];
    
    if(self.portNumber != 0)
        [urlString appendFormat:@":%d", self.portNumber];
    
    if(self.apiPath)
        [urlString appendFormat:@"/%@", self.apiPath];
    
    [urlString appendFormat:@"/%@", path];
    
    return [self operationWithURLString:urlString params:body httpMethod:method timeoutSeconds:timeout];
}

-(Leanplum_MKNetworkOperation*) operationWithURLString:(NSString*) urlString {
  
  return [self operationWithURLString:urlString
                               params:nil
                           httpMethod:@"GET"
                       timeoutSeconds:[LPConstantsState sharedState].networkTimeoutSeconds];
}

-(Leanplum_MKNetworkOperation*) operationWithURLString:(NSString*) urlString
                                       params:(NSMutableDictionary*) body {
  
  return [self operationWithURLString:urlString
                               params:body
                           httpMethod:@"GET"
                       timeoutSeconds:[LPConstantsState sharedState].networkTimeoutSeconds];
}

-(Leanplum_MKNetworkOperation*) operationWithURLString:(NSString*) urlString
                                                params:(NSMutableDictionary*) body
                                            httpMethod:(NSString*)method {
    return [self operationWithURLString:urlString
                                 params:body
                             httpMethod:method
                         timeoutSeconds:[LPConstantsState sharedState].networkTimeoutSeconds];
}

-(Leanplum_MKNetworkOperation*) operationWithURLString:(NSString*) urlString
                                       params:(NSMutableDictionary*) body
                                   httpMethod:(NSString*)method
                               timeoutSeconds:(int)timeout {
  
  Leanplum_MKNetworkOperation *operation = [[self.customOperationSubclass alloc] initWithURLString:urlString params:body httpMethod:method timeoutSeconds:timeout];
  
  [self prepareHeaders:operation];
  return operation;
}

-(void) prepareHeaders:(Leanplum_MKNetworkOperation*) operation {
  
  [operation addHeaders:self.customHeaders];
}

-(void) enqueueOperation:(Leanplum_MKNetworkOperation*) operation {
  
  NSParameterAssert(operation != nil);
  // Jump off the main thread, mainly for disk cache reading purposes
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      [_sharedNetworkQueue addOperation:operation];
  });
}

-(void) runSynchronously:(Leanplum_MKNetworkOperation*) operation {
    [operation startSync];
}

@end

#endif
