//
//  LPNetworkConstants.h
//  LeanplumSDK-iOS
//
//  Created by Dejan Krstevski
//  Copyright © 2020 Leanplum. All rights reserved.
//

#ifndef LPNetworkConstants_h
#define LPNetworkConstants_h


#endif /* LPNetworkConstants_h */

static NSString *LP_API_METHOD_START = @"start";
static NSString *LP_API_METHOD_GET_VARS = @"getVars";
static NSString *LP_API_METHOD_SET_VARS = @"setVars";
static NSString *LP_API_METHOD_STOP = @"stop";
static NSString *LP_API_METHOD_RESTART = @"restart";
static NSString *LP_API_METHOD_TRACK = @"track";
static NSString *LP_API_METHOD_TRACK_GEOFENCE = @"trackGeofence";
static NSString *LP_API_METHOD_ADVANCE = @"advance";
static NSString *LP_API_METHOD_PAUSE_SESSION = @"pauseSession";
static NSString *LP_API_METHOD_PAUSE_STATE = @"pauseState";
static NSString *LP_API_METHOD_RESUME_SESSION = @"resumeSession";
static NSString *LP_API_METHOD_RESUME_STATE = @"resumeState";
static NSString *LP_API_METHOD_MULTI = @"multi";
static NSString *LP_API_METHOD_REGISTER_FOR_DEVELOPMENT = @"registerDevice";
static NSString *LP_API_METHOD_SET_USER_ATTRIBUTES = @"setUserAttributes";
static NSString *LP_API_METHOD_SET_DEVICE_ATTRIBUTES = @"setDeviceAttributes";
static NSString *LP_API_METHOD_SET_TRAFFIC_SOURCE_INFO = @"setTrafficSourceInfo";
static NSString *LP_API_METHOD_UPLOAD_FILE = @"uploadFile";
static NSString *LP_API_METHOD_DOWNLOAD_FILE = @"downloadFile";
static NSString *LP_API_METHOD_HEARTBEAT = @"heartbeat";
static NSString *LP_API_METHOD_SAVE_VIEW_CONTROLLER_VERSION = @"saveInterface";
static NSString *LP_API_METHOD_SAVE_VIEW_CONTROLLER_IMAGE = @"saveInterfaceImage";
static NSString *LP_API_METHOD_GET_VIEW_CONTROLLER_VERSIONS_LIST = @"getViewControllerVersionsList";
static NSString *LP_API_METHOD_LOG = @"log";
static NSString *LP_API_METHOD_GET_INBOX_MESSAGES = @"getNewsfeedMessages";
static NSString *LP_API_METHOD_MARK_INBOX_MESSAGE_AS_READ = @"markNewsfeedMessageAsRead";
static NSString *LP_API_METHOD_DELETE_INBOX_MESSAGE = @"deleteNewsfeedMessage";
static NSString *LP_API_METHOD_GET_MIGRATE_STATE = @"getMigrateState";
static int LP_MAX_EVENTS_PER_API_CALL = 10000;
