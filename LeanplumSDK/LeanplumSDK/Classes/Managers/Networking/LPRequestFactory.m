//
//  LPRequestFactory.h
//  Leanplum
//
//  Created by Mayank Sanganeria on 6/30/18.
//  Copyright (c) 2018 Leanplum, Inc. All rights reserved.
//
//  Licensed to the Apache Software Foundation (ASF) under one
//  or more contributor license agreements.  See the NOTICE file
//  distributed with this work for additional information
//  regarding copyright ownership.  The ASF licenses this file
//  to you under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing,
//  software distributed under the License is distributed on an
//  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
//  KIND, either express or implied.  See the License for the
//  specific language governing permissions and limitations
//  under the License.

#import "LPRequestFactory.h"
#import "LPRequest.h"
#import "LPCountAggregator.h"
#import "LPNetworkConstants.h"

@implementation LPRequestFactory

#pragma mark Public methods

+ (LPRequest *)startWithParams:(NSDictionary *)params
{
    [[LPCountAggregator sharedAggregator] incrementCount:@"start_with_params"];
    return [LPRequestFactory createPostForApiMethod:LP_API_METHOD_START params:params];
}

+ (LPRequest *)getVarsWithParams:(NSDictionary *)params
{
    [[LPCountAggregator sharedAggregator] incrementCount:@"get_vars_with_params"];
    return [LPRequestFactory createPostForApiMethod:LP_API_METHOD_GET_VARS params:params];
}

+ (LPRequest *)setVarsWithParams:(NSDictionary *)params
{
    [[LPCountAggregator sharedAggregator] incrementCount:@"set_vars_with_params"];
    return [LPRequestFactory createPostForApiMethod:LP_API_METHOD_SET_VARS params:params];
}

+ (LPRequest *)stopWithParams:(NSDictionary *)params
{
    [[LPCountAggregator sharedAggregator] incrementCount:@"stop_with_params"];
    return [LPRequestFactory createPostForApiMethod:LP_API_METHOD_STOP params:params];
}

+ (LPRequest *)restartWithParams:(NSDictionary *)params
{
    [[LPCountAggregator sharedAggregator] incrementCount:@"restart_with_params"];
    return [LPRequestFactory createPostForApiMethod:LP_API_METHOD_RESTART params:params];
}

+ (LPRequest *)trackWithParams:(NSDictionary *)params
{
    [[LPCountAggregator sharedAggregator] incrementCount:@"track_with_params"];
    return [LPRequestFactory createPostForApiMethod:LP_API_METHOD_TRACK params:params];
}

+ (LPRequest *)trackGeofenceWithParams:(NSDictionary *)params
{
    [[LPCountAggregator sharedAggregator] incrementCount:@"track_geofence_with_params"];
    return [LPRequestFactory createPostForApiMethod:LP_API_METHOD_TRACK_GEOFENCE params:params];
}

+ (LPRequest *)advanceWithParams:(NSDictionary *)params
{
    [[LPCountAggregator sharedAggregator] incrementCount:@"advance_with_params"];
    return [LPRequestFactory createPostForApiMethod:LP_API_METHOD_ADVANCE params:params];
}

+ (LPRequest *)pauseSessionWithParams:(NSDictionary *)params
{
    [[LPCountAggregator sharedAggregator] incrementCount:@"pause_session_with_params"];
    return [LPRequestFactory createPostForApiMethod:LP_API_METHOD_PAUSE_SESSION params:params];
}

+ (LPRequest *)pauseStateWithParams:(NSDictionary *)params
{
    [[LPCountAggregator sharedAggregator] incrementCount:@"pause_state_with_params"];
    return [LPRequestFactory createPostForApiMethod:LP_API_METHOD_PAUSE_STATE params:params];
}

+ (LPRequest *)resumeSessionWithParams:(NSDictionary *)params
{
    [[LPCountAggregator sharedAggregator] incrementCount:@"resume_session_with_params"];
    return [LPRequestFactory createPostForApiMethod:LP_API_METHOD_RESUME_SESSION params:params];
}

+ (LPRequest *)resumeStateWithParams:(NSDictionary *)params
{
    [[LPCountAggregator sharedAggregator] incrementCount:@"resume_state_with_params"];
    return [LPRequestFactory createPostForApiMethod:LP_API_METHOD_RESUME_STATE params:params];
}

+ (LPRequest *)multiWithParams:(NSDictionary *)params
{
    [[LPCountAggregator sharedAggregator] incrementCount:@"multi_with_params"];
    return [LPRequestFactory createPostForApiMethod:LP_API_METHOD_MULTI params:params];
}

+ (LPRequest *)registerDeviceWithParams:(NSDictionary *)params
{
    [[LPCountAggregator sharedAggregator] incrementCount:@"register_device_with_params"];
    return [LPRequestFactory createPostForApiMethod:LP_API_METHOD_REGISTER_FOR_DEVELOPMENT params:params];
}

+ (LPRequest *)setUserAttributesWithParams:(NSDictionary *)params
{
    [[LPCountAggregator sharedAggregator] incrementCount:@"set_user_attributes_with_params"];
    return [LPRequestFactory createPostForApiMethod:LP_API_METHOD_SET_USER_ATTRIBUTES params:params];
}

+ (LPRequest *)setDeviceAttributesWithParams:(NSDictionary *)params
{
    [[LPCountAggregator sharedAggregator] incrementCount:@"set_device_attributes_with_params"];
    return [LPRequestFactory createPostForApiMethod:LP_API_METHOD_SET_DEVICE_ATTRIBUTES params:params];
}

+ (LPRequest *)setTrafficSourceInfoWithParams:(NSDictionary *)params
{
    [[LPCountAggregator sharedAggregator] incrementCount:@"set_traffic_source_info_with_params"];
    return [LPRequestFactory createPostForApiMethod:LP_API_METHOD_SET_TRAFFIC_SOURCE_INFO params:params];
}

+ (LPRequest *)uploadFileWithParams:(NSDictionary *)params
{
    [[LPCountAggregator sharedAggregator] incrementCount:@"upload_file_with_params"];
    return [LPRequestFactory createPostForApiMethod:LP_API_METHOD_UPLOAD_FILE params:params];
}

+ (LPRequest *)downloadFileWithParams:(NSDictionary *)params
{
    [[LPCountAggregator sharedAggregator] incrementCount:@"download_file_with_params"];
    return [LPRequestFactory createGetForApiMethod:LP_API_METHOD_DOWNLOAD_FILE params:params];
}

+ (LPRequest *)heartbeatWithParams:(NSDictionary *)params
{
    [[LPCountAggregator sharedAggregator] incrementCount:@"heartbeat_with_params"];
    return [LPRequestFactory createPostForApiMethod:LP_API_METHOD_HEARTBEAT params:params];
}

+ (LPRequest *)saveInterfaceWithParams:(NSDictionary *)params
{
    [[LPCountAggregator sharedAggregator] incrementCount:@"save_interface_with_params"];
    return [LPRequestFactory createPostForApiMethod:LP_API_METHOD_SAVE_VIEW_CONTROLLER_VERSION params:params];
}

+ (LPRequest *)saveInterfaceImageWithParams:(NSDictionary *)params
{
    [[LPCountAggregator sharedAggregator] incrementCount:@"save_interface_image_with_params"];
    return [LPRequestFactory createPostForApiMethod:LP_API_METHOD_SAVE_VIEW_CONTROLLER_IMAGE params:params];
}

+ (LPRequest *)getViewControllerVersionsListWithParams:(NSDictionary *)params
{
    [[LPCountAggregator sharedAggregator] incrementCount:@"get_view_controller_versions_list_with_params"];
    return [LPRequestFactory createPostForApiMethod:LP_API_METHOD_GET_VIEW_CONTROLLER_VERSIONS_LIST params:params];
}

+ (LPRequest *)logWithParams:(NSDictionary *)params
{
    [[LPCountAggregator sharedAggregator] incrementCount:@"log_with_params"];
    return [LPRequestFactory createPostForApiMethod:LP_API_METHOD_LOG params:params];
}

+ (LPRequest *)getNewsfeedMessagesWithParams:(NSDictionary *)params;
{
    [[LPCountAggregator sharedAggregator] incrementCount:@"get_newsfeed_messages_with_params"];
    return [LPRequestFactory createPostForApiMethod:LP_API_METHOD_GET_INBOX_MESSAGES params:params];
}

+ (LPRequest *)markNewsfeedMessageAsReadWithParams:(NSDictionary *)params
{
    [[LPCountAggregator sharedAggregator] incrementCount:@"mark_newsfeed_messages_as_read_with_params"];
    return [LPRequestFactory createPostForApiMethod:LP_API_METHOD_MARK_INBOX_MESSAGE_AS_READ params:params];
}

+ (LPRequest *)deleteNewsfeedMessageWithParams:(NSDictionary *)params
{
    [[LPCountAggregator sharedAggregator] incrementCount:@"delete_newsfeed_message_with_params"];
    return [LPRequestFactory createPostForApiMethod:LP_API_METHOD_DELETE_INBOX_MESSAGE params:params];
}

+ (LPRequest *)getMigrateState
{
    [[LPCountAggregator sharedAggregator] incrementCount:@"get_migrate_state"];
    return [LPRequestFactory createGetForApiMethod:LP_API_METHOD_GET_MIGRATE_STATE params:nil];
}

#pragma mark Private methods

+ (LPRequest *)createGetForApiMethod:(NSString *)apiMethod params:(NSDictionary *)params {
    [[LPCountAggregator sharedAggregator] incrementCount:@"create_get_for_api_method"];
    return [LPRequest get:apiMethod params:params];
}

+ (LPRequest *)createPostForApiMethod:(NSString *)apiMethod params:(NSDictionary *)params {
    [[LPCountAggregator sharedAggregator] incrementCount:@"create_post_for_api_method"];
    return [LPRequest post:apiMethod params:params];
}

@end
