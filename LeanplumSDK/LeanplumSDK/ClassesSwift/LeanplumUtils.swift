//
//  LeanplumUtils.swift
//  LeanplumSDK
//
//  Created by Nikola Zagorchev on 20.09.21.
//  Copyright © 2021 Leanplum. All rights reserved.

import Foundation

public class LeanplumUtils: NSObject {

    static func lpLog(type:Leanplum.LogTypeNew, format:String, _ args:CVarArg...) {
        LPLogv(type, format, getVaList(args))
    }
    
    static func getNotificationId(_ userInfo: [AnyHashable:Any]) -> String {
        if let occId = userInfo["lp_occurrence_id"] {
            return String(describing: occId)
        }
        return "-1"
    }
    
    @objc public static func messageIdFromUserInfo(_ userInfo: [AnyHashable : Any]) -> String? {
        if let messageId = userInfo[LP_KEY_PUSH_MESSAGE_ID] ?? userInfo[LP_KEY_PUSH_MUTE_IN_APP] ?? userInfo[LP_KEY_PUSH_NO_ACTION] ?? userInfo[LP_KEY_PUSH_NO_ACTION_MUTE] {
            return String(describing: messageId)
        }
        return nil
    }
    
    static func areActionsEmbedded(_ userInfo:[AnyHashable:Any]) -> Bool {
        return userInfo[LP_KEY_PUSH_ACTION] != nil ||
        userInfo[LP_KEY_PUSH_CUSTOM_ACTIONS] != nil
    }
    
    static func isMuted(_ userInfo:[AnyHashable:Any]) -> Bool {
        return userInfo[LP_KEY_PUSH_MUTE_IN_APP] != nil || userInfo[LP_KEY_PUSH_NO_ACTION_MUTE] != nil || userInfo[LP_KEY_PUSH_NO_ACTION] != nil
    }
    
    static func getNotificationText(_ userInfo:[AnyHashable:Any]) -> String? {
        // Handle payload "aps":{ "alert": "message" } and "aps":{ "alert": { "title": "...", "body": "message" }
        if let aps = userInfo["aps"] as? [AnyHashable : Any] {
            if let alert = aps["alert"] as? [AnyHashable : Any] {
                return alert["body"] as? String
            } else {
                return aps["alert"] as? String
            }
        }
        return nil
    }
    
    static func getAppName() -> String {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? ""
    }
}
