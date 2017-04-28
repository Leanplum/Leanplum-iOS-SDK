//
//  LPUIEditorWrapper.m
//  Leanplum
//
//  Created by Milos Jakovljevic on 3/27/17.
//  Copyright (c) 2017 Leanplum. All rights reserved.
//

#import "LPUIEditorWrapper.h"

@implementation LPUIEditorWrapper

NSString *LP_EDITOR_EVENT_NAME = @"__leanplum_editor_NAME";

NSString *LP_EDITOR_KEY_ACTION = @"action";
NSString *LP_EDITOR_KEY_MODE = @"mode";

NSString *LP_EDITOR_PARAM_START_UPDATING = @"editorStartUpdating";
NSString *LP_EDITOR_PARAM_STOP_UPDATING = @"editorStopUpdate";
NSString *LP_EDITOR_PARAM_SEND_UPDATE = @"editorSendUpdate";
NSString *LP_EDITOR_PARAM_SEND_UPDATE_DELAYED = @"editorSendUpdateDelayed";
NSString *LP_EDITOR_PARAM_SET_MODE = @"editorSetMode";
NSString *LP_EDITOR_PARAM_AUTOMATIC_SCREEN_TRACKING = @"editorAutomaticScreenTracking";

+ (void)startUpdating
{
    NSDictionary* data = @{
                           LP_EDITOR_KEY_ACTION: LP_EDITOR_PARAM_START_UPDATING
                           };
    [[NSNotificationCenter defaultCenter] postNotificationName:LP_EDITOR_EVENT_NAME
                                                        object:nil
                                                      userInfo:data];
}

+ (void)stopUpdating
{
    NSDictionary* data = @{
                           LP_EDITOR_KEY_ACTION: LP_EDITOR_PARAM_STOP_UPDATING
                           };
    [[NSNotificationCenter defaultCenter] postNotificationName:LP_EDITOR_EVENT_NAME
                                                        object:nil
                                                      userInfo:data];
}

+ (void)sendUpdate
{
    NSDictionary* data = @{
                           LP_EDITOR_KEY_ACTION: LP_EDITOR_PARAM_SEND_UPDATE
                           };
    [[NSNotificationCenter defaultCenter] postNotificationName:LP_EDITOR_EVENT_NAME
                                                        object:nil
                                                      userInfo:data];
}

+ (void)sendUpdateDelayed
{
    NSDictionary* data = @{
                           LP_EDITOR_KEY_ACTION: LP_EDITOR_PARAM_SEND_UPDATE_DELAYED
                           };
    [[NSNotificationCenter defaultCenter] postNotificationName:LP_EDITOR_EVENT_NAME
                                                        object:nil
                                                      userInfo:data];
}

+ (void)setMode:(NSInteger)mode
{
    NSDictionary* data = @{
                           LP_EDITOR_KEY_ACTION: LP_EDITOR_PARAM_SET_MODE,
                           LP_EDITOR_KEY_MODE: @(mode)
                           };
    [[NSNotificationCenter defaultCenter] postNotificationName:LP_EDITOR_EVENT_NAME
                                                        object:nil
                                                      userInfo:data];
}

+ (void)enableAutomaticScreenTracking
{
    NSDictionary* data = @{
                           LP_EDITOR_KEY_ACTION: LP_EDITOR_PARAM_AUTOMATIC_SCREEN_TRACKING
                           };
    [[NSNotificationCenter defaultCenter] postNotificationName:LP_EDITOR_EVENT_NAME
                                                        object:nil
                                                      userInfo:data];
}
@end
