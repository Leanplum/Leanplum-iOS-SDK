//
//  EnumConstants.h
//  Pods
//
//  Created by Grace on 12/19/18.
//


#ifndef EnumConstants_h
#define EnumConstants_h

@interface LPEnumConstants : NSObject {}

typedef enum {
    LPEnterRegion,
    LPExitRegion
} LPGeofenceEventType;


+ (NSString *)getEventNameFromGeofenceType:(LPGeofenceEventType)event;
@end

#endif /* EnumConstants_h */
