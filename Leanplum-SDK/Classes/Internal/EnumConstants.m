//
//  EnumConstants.m
//  Leanplum-iOS-SDK-source
//
//  Created by Grace on 12/19/18.
//

#import "EnumConstants.h"

@implementation LPEnumConstants

+ (NSString *) getEventNameFromGeofenceType:(LPGeofenceEventType)event {
    NSString *result = nil;
    
    switch(event) {
        case LPEnterRegion:
            result = @"enter_region";
            break;
        case LPExitRegion:
            result = @"exit_region";
            break;
        default:
            [NSException raise:NSGenericException format:@"Unexpected geofenceEventType."];
    }
    
    return result;
}

@end
