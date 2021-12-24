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
        if let messageId = userInfo[LP_KEY_PUSH_MESSAGE_ID] ??
            userInfo[LP_KEY_PUSH_MUTE_IN_APP] ??
            userInfo[LP_KEY_PUSH_NO_ACTION] ??
            userInfo[LP_KEY_PUSH_NO_ACTION_MUTE] {
            return String(describing: messageId)
        }
        return nil
    }
}
