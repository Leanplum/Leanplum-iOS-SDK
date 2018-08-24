//
//  LPRequestFactory.m
//  Leanplum-iOS-SDK-source
//
//  Created by Mayank Sanganeria on 8/24/18.
//

#import "LPRequestFactory.h"
#import "LeanplumRequest.h"
#import "LeanplumInternal.h"

@implementation LPRequestFactory

+ (id<LPRequesting>)get:(NSString *)apiMethod params:(NSDictionary *)params {
    LPLogType level = [apiMethod isEqualToString:LP_METHOD_LOG] ? LPDebug : LPVerbose;
    LPLog(level, @"Will call API method %@ with arguments %@", apiMethod, params);
    return [[LeanplumRequest alloc] initWithHttpMethod:@"GET" apiMethod:apiMethod params:params];
}

+ (id<LPRequesting>)post:(NSString *)apiMethod params:(NSDictionary *)params {
    LPLogType level = [apiMethod isEqualToString:LP_METHOD_LOG] ? LPDebug : LPVerbose;
    LPLog(level, @"Will call API method %@ with arguments %@", apiMethod, params);
    return [[LeanplumRequest alloc] initWithHttpMethod:@"POST" apiMethod:apiMethod params:params];
}

@end
