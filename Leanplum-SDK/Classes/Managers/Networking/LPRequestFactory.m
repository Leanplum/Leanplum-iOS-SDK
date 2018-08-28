
#import "LPRequestFactory.h"
#import "LeanplumRequest.h"
#import "LPRequest.h"
#import "LPFeatureFlagManager.h"

@implementation LPRequestFactory

+ (id<LPRequesting>)get:(NSString *)apiMethod params:(NSDictionary *)params {
//    LPLogType level = [apiMethod isEqualToString:LP_METHOD_LOG] ? LPDebug : LPVerbose;
//    LPLog(level, @"Will call API method %@ with arguments %@", apiMethod, params);
    if ([[LPFeatureFlagManager sharedManager] isFeatureFlagEnabled:LP_FEATURE_FLAG_REQUEST_REFACTOR]) {
        return [LPRequest get:apiMethod params:params];
    }
    return [LeanplumRequest get:apiMethod params:params];
}

+ (id<LPRequesting>)post:(NSString *)apiMethod params:(NSDictionary *)params {
//    LPLogType level = [apiMethod isEqualToString:LP_METHOD_LOG] ? LPDebug : LPVerbose;
//    LPLog(level, @"Will call API method %@ with arguments %@", apiMethod, params);
    if ([[LPFeatureFlagManager sharedManager] isFeatureFlagEnabled:LP_FEATURE_FLAG_REQUEST_REFACTOR]) {
        return [LPRequest post:apiMethod params:params];
    }
    return [LeanplumRequest post:apiMethod params:params];
}

@end
