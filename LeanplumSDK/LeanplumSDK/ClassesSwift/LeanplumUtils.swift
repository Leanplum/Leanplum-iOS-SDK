//
//  LeanplumUtils.swift
//  LeanplumSDK
//
//  Created by Nikola Zagorchev on 20.09.21.
//

import Foundation

public class LeanplumUtils: NSObject {
    
    @objc public static func checkIfPushNotificationIdIsInDefaults(_ pushId: String) -> Bool {
        //TODO: decode
        if var recievedPushIds = UserDefaults.standard.value(forKey: LEANPLUM_DEFAULTS_PUSH_IDS_KEY) as? Dictionary<String, Any> {
            if recievedPushIds.keys.contains(pushId) {
//                return isDuplicate and or handle it
                return true
            } else {
                recievedPushIds[pushId] = Date()
                //TODO: encode
                UserDefaults.standard.setValue(recievedPushIds, forKey: LEANPLUM_DEFAULTS_PUSH_IDS_KEY)
                return false
            }
        } else {
            var recievedPushIds: [String: Any] = [:]
            recievedPushIds[pushId] = Date()
            UserDefaults.standard.setValue(recievedPushIds, forKey: LEANPLUM_DEFAULTS_PUSH_IDS_KEY)
        }
        return false
    }
    
//    @objc public static func getLastPushId() -> String? {
//        guard let recievedPushIds = UserDefaults.standard.value(forKey: LEANPLUM_DEFAULTS_PUSH_IDS_KEY) as? Dictionary<String, Any> else {
//            return nil
//        }
//        for pushId in recievedPushIds.keys {
//            //TODO: logic to get newest push id if needed
//        }
//        return UserDefaults.standard.value(forKey: "lastPushIdKey") as? String
//    }
//
    @objc public func messageIdFromUserInfo(_ userInfo: Dictionary<String, Any>) -> String? {
        if let messageId = userInfo[LP_KEY_PUSH_MESSAGE_ID] as? String {
            return messageId
        }
        if let messageId = userInfo[LP_KEY_PUSH_MUTE_IN_APP] as? String {
            return messageId
        }
        if let messageId = userInfo[LP_KEY_PUSH_NO_ACTION] as? String {
            return messageId
        }
        if let messageId = userInfo[LP_KEY_PUSH_NO_ACTION_MUTE] as? String {
            return messageId
        }
        return nil
    }
    
    @objc public func hexadecimalStringFromData(_ data: NSData) -> String {
        return (data as Data).hexEncodedString()
    }
}

//Push Notifications Utils
extension LeanplumUtils {
    @objc static public func enableSystemPush() {
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
                if let error = error {
                    // Handle the error here.
                    print("Error: \(error)")
                }
                
                if granted {
                    DispatchQueue.main.async {
                        UIApplication.shared.registerForRemoteNotifications()
                    }
                }
            }
        } else {
            
        }
    }
    
    @available(iOS 12.0, *)
    @objc static public func enableProvisionalPush() {
        UNUserNotificationCenter.current().requestAuthorization(options: .provisional) { granted, error in
            if let error = error {
                // Handle the error here.
                print("Error: \(error)")
            }
            
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }
    
    @objc public static func isUNUserNotificationCenterDelegateNil() -> Bool {
        if #available(iOS 10.0, *) {
            return UNUserNotificationCenter.current().delegate == nil
        }
        return true
    }
    
    @objc public static func isRemoteNotificationsBackgroundModeEnabled() -> Bool {
        if let backgroundModes = Bundle.main.object(forInfoDictionaryKey: "UIBackgroundModes") as? [String] {
            return backgroundModes.firstIndex(of: "remote-notification") != nil
        }
        return false
    }
    
    @objc public static func pushToken() {
        //TODO: return push token from defaults
    }
}






