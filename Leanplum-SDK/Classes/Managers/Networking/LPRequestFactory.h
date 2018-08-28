#import <Foundation/Foundation.h>
#import "LPRequesting.h"

@interface LPRequestFactory : NSObject

//+ (id<LPRequesting>)get:(NSString *)apiMethod params:(NSDictionary *)params;
//+ (id<LPRequesting>)post:(NSString *)apiMethod params:(NSDictionary *)params;

+ (id<LPRequesting>)apiMethodStartWithParams:(NSDictionary *)params;
+ (id<LPRequesting>)apiMethodGetVarsWithParams:(NSDictionary *)params;
+ (id<LPRequesting>)apiMethodSetVarsWithParams:(NSDictionary *)params;
+ (id<LPRequesting>)apiMethodStopWithParams:(NSDictionary *)params;
+ (id<LPRequesting>)apiMethodRestartWithParams:(NSDictionary *)params;
+ (id<LPRequesting>)apiMethodTrackWithParams:(NSDictionary *)params;
+ (id<LPRequesting>)apiMethodAdvanceWithParams:(NSDictionary *)params;
+ (id<LPRequesting>)apiMethodPauseSessionWithParams:(NSDictionary *)params;
+ (id<LPRequesting>)apiMethodPauseStateWithParams:(NSDictionary *)params;
+ (id<LPRequesting>)apiMethodResumeSessionWithParams:(NSDictionary *)params;
+ (id<LPRequesting>)apiMethodResumeStateWithParams:(NSDictionary *)params;
+ (id<LPRequesting>)apiMethodMultiWithParams:(NSDictionary *)params;
+ (id<LPRequesting>)apiMethodRegisterDeviceWithParams:(NSDictionary *)params;
+ (id<LPRequesting>)apiMethodSetUserAttributesWithParams:(NSDictionary *)params;
+ (id<LPRequesting>)apiMethodSetDeviceAttributesWithParams:(NSDictionary *)params;
+ (id<LPRequesting>)apiMethodSetTrafficSourceInfoWithParams:(NSDictionary *)params;
+ (id<LPRequesting>)apiMethodUploadFileWithParams:(NSDictionary *)params;
+ (id<LPRequesting>)apiMethodDownloadFileWithParams:(NSDictionary *)params;
+ (id<LPRequesting>)apiMethodHeartbeatWithParams:(NSDictionary *)params;
+ (id<LPRequesting>)apiMethodSaveInterfaceWithParams:(NSDictionary *)params;
+ (id<LPRequesting>)apiMethodSaveInterfaceImageWithParams:(NSDictionary *)params;
+ (id<LPRequesting>)apiMethodGetViewControllerVersionsListWithParams:(NSDictionary *)params;
+ (id<LPRequesting>)apiMethodLogWithParams:(NSDictionary *)params;
+ (id<LPRequesting>)apiMethodGetNewsfeedMessagesWithParams:(NSDictionary *)params;
+ (id<LPRequesting>)apiMethodMarkNewsfeedMessageAsReadWithParams:(NSDictionary *)params;
+ (id<LPRequesting>)apiMethodDeleteNewsfeedMessageWithParams:(NSDictionary *)params;

@end
