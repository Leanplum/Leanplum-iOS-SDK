//
//  LPUIEditorWrapper.h
//  Leanplum
//
//  Created by Milos Jakovljevic on 3/27/17.
//  Copyright (c) 2017 Leanplum. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * UIEditor wrapper used to communicate with UIEditor through NSNotificationCenter.
 */
@interface LPUIEditorWrapper : NSObject

/**
 * UIEditor NSNotification event name.
 */
OBJC_EXPORT NSString *LP_EDITOR_EVENT_NAME;

/**
 * UIEditor NSNotification UserData default keys.
 */
OBJC_EXPORT NSString *LP_EDITOR_KEY_ACTION;
OBJC_EXPORT NSString *LP_EDITOR_KEY_MODE;

/**
 * UIEditor NSNotification UserData default action params.
 */
OBJC_EXPORT NSString *LP_EDITOR_PARAM_START_UPDATING;
OBJC_EXPORT NSString *LP_EDITOR_PARAM_STOP_UPDATING;
OBJC_EXPORT NSString *LP_EDITOR_PARAM_SEND_UPDATE;
OBJC_EXPORT NSString *LP_EDITOR_PARAM_SEND_UPDATE_DELAYED;
OBJC_EXPORT NSString *LP_EDITOR_PARAM_SET_MODE;

/**
 * UIEditor NSNotification UserData default mode params.
 */
OBJC_EXPORT NSString *LP_EDITOR_PARAM_AUTOMATIC_SCREEN_TRACKING;

/**
 * Sends notification to UI Editor to start updating.
 */
+ (void)startUpdating;

/**
 * Sends notification to UI Editor to stop updating.
 */
+ (void)stopUpdating;

/**
 * Sends notification to UI Editor to send update.
 */
+ (void)sendUpdate;

/**
 * Sends notification to UI Editor to set mode.
 */
+ (void)setMode:(NSInteger)mode;

/**
 * Sends notification to UI Editor to send delayed update.
 */
+ (void)sendUpdateDelayed;

/**
 * Sends notification to UI Editor to enable automatic screen tracking.
 */
+ (void)enableAutomaticScreenTracking;

@end
