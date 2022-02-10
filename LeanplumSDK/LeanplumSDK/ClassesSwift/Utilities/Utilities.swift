//
//  Utilities.swift
//  LeanplumSDK
//
//  Created by Nikola Zagorchev on 20.09.21.
//  Copyright © 2021 Leanplum. All rights reserved.

import Foundation

// TODO: Remove Utilities class when we add proper models
public class Utilities: NSObject {    
    /**
     * Returns Leanplum message Id from Notification userInfo.
     * Use this method to identify Leanplum Notifications
     */
    @objc public static func messageIdFromUserInfo(_ userInfo: [AnyHashable: Any]) -> String? {
        if let messageId = userInfo[Constants.PushNotifications.Keys.messageId] ??
            userInfo[Constants.PushNotifications.Keys.muteInApp] ??
            userInfo[Constants.PushNotifications.Keys.noAction] ??
            userInfo[Constants.PushNotifications.Keys.noActionMute] {
            return String(describing: messageId)
        }
        return nil
    }
}
