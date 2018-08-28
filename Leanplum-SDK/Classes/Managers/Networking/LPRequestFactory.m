
#import "LPRequestFactory.h"
#import "Constants.h"
#import "LeanplumRequest.h"
#import "LPRequest.h"
#import "LPFeatureFlagManager.h"

NSString *LP_API_METHOD_START = @"start";
NSString *LP_API_METHOD_GET_VARS = @"getVars";
NSString *LP_API_METHOD_SET_VARS = @"setVars";
NSString *LP_API_METHOD_STOP = @"stop";
NSString *LP_API_METHOD_RESTART = @"restart";
NSString *LP_API_METHOD_TRACK = @"track";
NSString *LP_API_METHOD_ADVANCE = @"advance";
NSString *LP_API_METHOD_PAUSE_SESSION = @"pauseSession";
NSString *LP_API_METHOD_PAUSE_STATE = @"pauseState";
NSString *LP_API_METHOD_RESUME_SESSION = @"resumeSession";
NSString *LP_API_METHOD_RESUME_STATE = @"resumeState";
NSString *LP_API_METHOD_MULTI = @"multi";
NSString *LP_API_METHOD_REGISTER_FOR_DEVELOPMENT = @"registerDevice";
NSString *LP_API_METHOD_SET_USER_ATTRIBUTES = @"setUserAttributes";
NSString *LP_API_METHOD_SET_DEVICE_ATTRIBUTES = @"setDeviceAttributes";
NSString *LP_API_METHOD_SET_TRAFFIC_SOURCE_INFO = @"setTrafficSourceInfo";
NSString *LP_API_METHOD_UPLOAD_FILE = @"uploadFile";
NSString *LP_API_METHOD_DOWNLOAD_FILE = @"downloadFile";
NSString *LP_API_METHOD_HEARTBEAT = @"heartbeat";
NSString *LP_API_METHOD_SAVE_VIEW_CONTROLLER_VERSION = @"saveInterface";
NSString *LP_API_METHOD_SAVE_VIEW_CONTROLLER_IMAGE = @"saveInterfaceImage";
NSString *LP_API_METHOD_GET_VIEW_CONTROLLER_VERSIONS_LIST = @"getViewControllerVersionsList";
NSString *LP_API_METHOD_LOG = @"log";
NSString *LP_API_METHOD_GET_INBOX_MESSAGES = @"getNewsfeedMessages";
NSString *LP_API_METHOD_MARK_INBOX_MESSAGE_AS_READ = @"markNewsfeedMessageAsRead";
NSString *LP_API_METHOD_DELETE_INBOX_MESSAGE = @"deleteNewsfeedMessage";

@implementation LPRequestFactory

+ (id<LPRequesting>)get:(NSString *)apiMethod params:(NSDictionary *)params {
//    LPLogType level = [apiMethod isEqualToString:LP_API_METHOD_LOG] ? LPDebug : LPVerbose;
//    LPLog(level, @"Will call API method %@ with arguments %@", apiMethod, params);
    if ([[LPFeatureFlagManager sharedManager] isFeatureFlagEnabled:LP_FEATURE_FLAG_REQUEST_REFACTOR]) {
        return [LPRequest get:apiMethod params:params];
    }
    return [LeanplumRequest get:apiMethod params:params];
}

+ (id<LPRequesting>)post:(NSString *)apiMethod params:(NSDictionary *)params {
//    LPLogType level = [apiMethod isEqualToString:LP_API_METHOD_LOG] ? LPDebug : LPVerbose;
//    LPLog(level, @"Will call API method %@ with arguments %@", apiMethod, params);
    if ([[LPFeatureFlagManager sharedManager] isFeatureFlagEnabled:LP_FEATURE_FLAG_REQUEST_REFACTOR]) {
        return [LPRequest post:apiMethod params:params];
    }
    return [LeanplumRequest post:apiMethod params:params];
}

+ (id<LPRequesting>)apiMethodStartWithParams:(NSDictionary *)params
{
    return [LPRequestFactory post:LP_API_METHOD_START params:params];
}
+ (id<LPRequesting>)apiMethodGetVarsWithParams:(NSDictionary *)params;
{
    return [LPRequestFactory post:LP_API_METHOD_GET_VARS params:params];
}

+ (id<LPRequesting>)apiMethodSetVarsWithParams:(NSDictionary *)params;
{
    return [LPRequestFactory post:LP_API_METHOD_SET_VARS params:params];
}

+ (id<LPRequesting>)apiMethodStopWithParams:(NSDictionary *)params;
{
    return [LPRequestFactory post:LP_API_METHOD_STOP params:params];
}

+ (id<LPRequesting>)apiMethodRestartWithParams:(NSDictionary *)params;
{
    return [LPRequestFactory post:LP_API_METHOD_RESTART params:params];
}

+ (id<LPRequesting>)apiMethodTrackWithParams:(NSDictionary *)params;
{
    return [LPRequestFactory post:LP_API_METHOD_TRACK params:params];
}

+ (id<LPRequesting>)apiMethodAdvanceWithParams:(NSDictionary *)params;
{
    return [LPRequestFactory post:LP_API_METHOD_ADVANCE params:params];
}

+ (id<LPRequesting>)apiMethodPauseSessionWithParams:(NSDictionary *)params;
{
    return [LPRequestFactory post:LP_API_METHOD_PAUSE_SESSION params:params];
}

+ (id<LPRequesting>)apiMethodPauseStateWithParams:(NSDictionary *)params;
{
    return [LPRequestFactory post:LP_API_METHOD_PAUSE_STATE params:params];
}

+ (id<LPRequesting>)apiMethodResumeSessionWithParams:(NSDictionary *)params;
{
    return [LPRequestFactory post:LP_API_METHOD_RESUME_SESSION params:params];
}

+ (id<LPRequesting>)apiMethodResumeStateWithParams:(NSDictionary *)params;
{
    return [LPRequestFactory post:LP_API_METHOD_RESUME_STATE params:params];
}

+ (id<LPRequesting>)apiMethodMultiWithParams:(NSDictionary *)params;
{
    return [LPRequestFactory post:LP_API_METHOD_MULTI params:params];
}

+ (id<LPRequesting>)apiMethodRegisterDeviceWithParams:(NSDictionary *)params;
{
    return [LPRequestFactory post:LP_API_METHOD_REGISTER_FOR_DEVELOPMENT params:params];
}

+ (id<LPRequesting>)apiMethodSetUserAttributesWithParams:(NSDictionary *)params;
{
    return [LPRequestFactory post:LP_API_METHOD_SET_USER_ATTRIBUTES params:params];
}

+ (id<LPRequesting>)apiMethodSetDeviceAttributesWithParams:(NSDictionary *)params;
{
    return [LPRequestFactory post:LP_API_METHOD_SET_DEVICE_ATTRIBUTES params:params];
}

+ (id<LPRequesting>)apiMethodSetTrafficSourceInfoWithParams:(NSDictionary *)params;
{
    return [LPRequestFactory post:LP_API_METHOD_SET_TRAFFIC_SOURCE_INFO params:params];
}

+ (id<LPRequesting>)apiMethodUploadFileWithParams:(NSDictionary *)params;
{
    return [LPRequestFactory post:LP_API_METHOD_UPLOAD_FILE params:params];
}

+ (id<LPRequesting>)apiMethodDownloadFileWithParams:(NSDictionary *)params;
{
    return [LPRequestFactory get:LP_API_METHOD_DOWNLOAD_FILE params:params];
}

+ (id<LPRequesting>)apiMethodHeartbeatWithParams:(NSDictionary *)params;
{
    return [LPRequestFactory post:LP_API_METHOD_HEARTBEAT params:params];
}

+ (id<LPRequesting>)apiMethodSaveInterfaceWithParams:(NSDictionary *)params;
{
    return [LPRequestFactory post:LP_API_METHOD_SAVE_VIEW_CONTROLLER_VERSION params:params];
}

+ (id<LPRequesting>)apiMethodSaveInterfaceImageWithParams:(NSDictionary *)params;
{
    return [LPRequestFactory post:LP_API_METHOD_SAVE_VIEW_CONTROLLER_IMAGE params:params];
}

+ (id<LPRequesting>)apiMethodGetViewControllerVersionsListWithParams:(NSDictionary *)params;
{
    return [LPRequestFactory post:LP_API_METHOD_GET_VIEW_CONTROLLER_VERSIONS_LIST params:params];
}

+ (id<LPRequesting>)apiMethodLogWithParams:(NSDictionary *)params;
{
    return [LPRequestFactory post:LP_API_METHOD_LOG params:params];
}

+ (id<LPRequesting>)apiMethodGetNewsfeedMessagesWithParams:(NSDictionary *)params;
{
    return [LPRequestFactory post:LP_API_METHOD_GET_INBOX_MESSAGES params:params];
}

+ (id<LPRequesting>)apiMethodMarkNewsfeedMessageAsReadWithParams:(NSDictionary *)params;
{
    return [LPRequestFactory post:LP_API_METHOD_MARK_INBOX_MESSAGE_AS_READ params:params];
}

+ (id<LPRequesting>)apiMethodDeleteNewsfeedMessageWithParams:(NSDictionary *)params;
{
    return [LPRequestFactory post:LP_API_METHOD_DELETE_INBOX_MESSAGE params:params];
}



@end
