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
        var notifId = "-1"
        let id:Int = userInfo["id"] as? Int ?? -1
        if id == -1, let occId = userInfo["lp_occurrence_id"] as? String {
            notifId = occId
        } else {
            notifId = String(id)
        }
        
        return notifId
    }
    
    @objc public static func messageIdFromUserInfo(_ userInfo: [AnyHashable : Any]) -> String? {
        let messageId = userInfo[LP_KEY_PUSH_MESSAGE_ID] ?? userInfo[LP_KEY_PUSH_MUTE_IN_APP] ?? userInfo[LP_KEY_PUSH_NO_ACTION] ?? userInfo[LP_KEY_PUSH_NO_ACTION_MUTE]
        
        return messageId as? String
    }
    
    static func areActionsEmbedded(_ userInfo:[AnyHashable:Any]) -> Bool {
        return userInfo[LP_KEY_PUSH_ACTION] != nil ||
        userInfo[LP_KEY_PUSH_CUSTOM_ACTIONS] != nil
    }
    
    static func isMuted(_ userInfo:[AnyHashable:Any]) -> Bool {
        return userInfo[LP_KEY_PUSH_MUTE_IN_APP] != nil || userInfo[LP_KEY_PUSH_NO_ACTION_MUTE] != nil
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
