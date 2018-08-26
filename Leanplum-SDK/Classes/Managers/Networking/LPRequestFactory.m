
#import "LPRequestFactory.h"
#import "LeanplumRequest.h"

@implementation LPRequestFactory

+ (id<LPRequesting>)get:(NSString *)apiMethod params:(NSDictionary *)params {
//    LPLogType level = [apiMethod isEqualToString:LP_METHOD_LOG] ? LPDebug : LPVerbose;
//    LPLog(level, @"Will call API method %@ with arguments %@", apiMethod, params);
    return [LeanplumRequest get:apiMethod params:params];
}

+ (id<LPRequesting>)post:(NSString *)apiMethod params:(NSDictionary *)params {
//    LPLogType level = [apiMethod isEqualToString:LP_METHOD_LOG] ? LPDebug : LPVerbose;
//    LPLog(level, @"Will call API method %@ with arguments %@", apiMethod, params);
    return [LeanplumRequest post:apiMethod params:params];
}

@end
