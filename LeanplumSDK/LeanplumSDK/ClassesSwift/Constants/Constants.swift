//
//  Constants.swift
//  LeanplumSDK
//
//  Created by Dejan Krstevski on 8.02.22.
//

/*
 This is a class for bridging swift constants into objc
 should be deleteted when everything is transfered in swift...
 */

import Foundation

@objc
public class ConstantsSwift: NSObject {
    
    //MARK: Push Notificaitons
    //LP_KEY_PUSH_MESSAGE_ID
    @objc
    public class func lpKeyPushMessageId() -> String {
        return Constants.PushNotifications.Keys.messageId
    }
    
    //LP_KEY_PUSH_MUTE_IN_APP
    @objc
    public class func lpKeyPushMuteInApp() -> String {
        return Constants.PushNotifications.Keys.muteInApp
    }
    
    //LP_KEY_PUSH_NO_ACTION
    @objc
    public class func lpKeyPushNoAction() -> String {
        return Constants.PushNotifications.Keys.noAction
    }
    
    //LP_KEY_PUSH_NO_ACTION_MUTE
    @objc
    public class func lpKeyPushNoActionMute() -> String {
        return Constants.PushNotifications.Keys.noActionMute
    }
    
    //LP_KEY_PUSH_OCCURRENCE_ID
    @objc
    public class func lpKeyPushOccurrenceId() -> String {
        return Constants.PushNotifications.Keys.occurrenceId
    }
    
    //LP_KEY_LOCAL_NOTIF
    @objc
    public class func lpKeyLocalNotification() -> String {
        return Constants.LocalNotifications.localNotificationKey
    }
    
    //LP_PUSH_NOTIFICATION_ACTION
    @objc
    public class func lpPushNotificationAction() -> String {
        return Constants.PushNotifications.pushNotificationAction
    }
    
    //MARK: Device
    //LP_PARAM_DEVICE_PUSH_TOKEN
    @objc
    public class func lpParamDevicePushToken() -> String {
        return Constants.Device.Leanplum.Parameter.pushToken
    }
}
