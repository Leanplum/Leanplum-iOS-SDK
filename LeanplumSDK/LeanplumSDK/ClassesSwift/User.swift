//
//  User.swift
//  LeanplumSDK
//
//  Created by Nikola Zagorchev on 25.02.22.
//  Copyright © 2022 Leanplum. All rights reserved.

import Foundation

@objc public class User: NSObject {
    public struct UserKey {
        public let appId: String
        public let userId: String
        public let deviceId: String
    }
    
    @objc public var userId: String?
    @objc public var deviceId: String?
    
    @objc public var pushToken: String? {
        get {
            UserDefaults.standard.string(forKey: tokenKey)
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: tokenKey)
        }
    }
    
    var notificationSettings: [AnyHashable: Any]? {
        get {
            UserDefaults.standard.dictionary(forKey: settingsKey)
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: settingsKey)
        }
    }
    
    public var key: UserKey? {
        get {
            guard
                let appId = ApiConfig.shared.appId,
                let userId = self.userId,
                let deviceId = self.deviceId
            else {
                return nil
            }
            
            return UserKey(appId: appId, userId: userId, deviceId: deviceId)
        }
    }
    
    private var tokenKey: String {
        get {
            guard
                let userKey = key
            else {
                return ""
            }
            return String(format: LEANPLUM_DEFAULTS_PUSH_TOKEN_KEY,
                          userKey.appId,
                          userKey.userId,
                          userKey.deviceId)
        }
    }
    
    private var settingsKey: String {
        get {
            guard
                let userKey = key
            else {
                return ""
            }
            return String(format: LEANPLUM_DEFAULTS_USER_NOTIFICATION_SETTINGS_KEY,
                          userKey.appId,
                          userKey.userId,
                          userKey.deviceId)
        }
    }
}
