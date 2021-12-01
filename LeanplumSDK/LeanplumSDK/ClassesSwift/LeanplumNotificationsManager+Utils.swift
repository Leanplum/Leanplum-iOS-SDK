//
//  LeanplumPushNotificationUtils.swift
//  LeanplumSDK
//
//  Created by Nikola Zagorchev on 20.09.21.
//  Copyright © 2021 Leanplum. All rights reserved.

import Foundation

@objc extension LeanplumNotificationsManager {
    
    func getFormattedDeviceTokenFromData(_ token: Data) -> String {
        var formattedToken = token.hexEncodedString()
        formattedToken = formattedToken.replacingOccurrences(of: "<", with: "")
            .replacingOccurrences(of: ">", with: "")
            .replacingOccurrences(of: " ", with: "")
        return formattedToken
    }
    
    @objc public func enableSystemPush() {
        UserDefaults.standard.set(true, forKey: DEFAULTS_LEANPLUM_ENABLED_PUSH)
        disableAskToAsk()
        if let block = Leanplum.pushSetupBlock() {
            // If the app used [Leanplum setPushSetup:...], call the block.
            block()
            return
        }
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
                if let error = error {
                    // Handle the error here.
                    LeanplumUtils.lpLog(type: .error, format: "Error: %@", error.localizedDescription)
                }
                
                //Register for remote notificaiton to create and send push token to server
                //no metter if the request was granted or has error, push token will be generated
                //and later if user decides to go into the settings and enables push notificaitons
                //we will have token and will only update push types
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        } else if #available(iOS 8.0, *) {
            UIApplication.shared.registerUserNotificationSettings(UIUserNotificationSettings(types: [.badge, .sound, .alert],
                                                                                             categories: nil))
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
    
    @available(iOS 12.0, *)
    @objc public func enableProvisionalPush() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound, .provisional]) { granted, error in
            if let error = error {
                // Handle the error here.
                LeanplumUtils.lpLog(type: .error, format: "Error: %@", error.localizedDescription)
            }
            
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
                
            }
        }
    }
    
    @objc public func pushToken() -> String? {
        //return push token from defaults
        guard let key = pushTokenKey() else {
            return nil
        }
        return UserDefaults.standard.string(forKey: key)
    }
    
    @objc public func updatePushToken(_ token: String) {
        guard let key = pushTokenKey() else {
            return
        }
        UserDefaults.standard.setValue(token, forKey: key)
    }
    
    private func pushTokenKey() -> String? {
        guard let appId = LPAPIConfig.shared().appId, let userId = LPAPIConfig.shared().userId, let deviceId = LPAPIConfig.shared().deviceId else {
            return nil
        }
        return String(format: LEANPLUM_DEFAULTS_PUSH_TOKEN_KEY, appId, userId, deviceId)
    }
    
    @objc public func removePushToken() {
        guard let key = pushTokenKey() else {
            return
        }
        UserDefaults.standard.removeObject(forKey: key)
    }
    
    @objc public func isPushEnabled() -> Bool {
        if !Thread.isMainThread {
            var output = false
            DispatchQueue.main.sync(execute: { [self] in
                output = isPushEnabled()
            })
            return output
        }
        
        if UIApplication.shared.responds(to: #selector(getter: UIApplication.isRegisteredForRemoteNotifications)) {
            return UIApplication.shared.isRegisteredForRemoteNotifications
        }
        
        return false
    }
    
    @objc public func disableAskToAsk() {
        UserDefaults.standard.setValue(true, forKey: DEFAULTS_ASKED_TO_PUSH)
    }
    
    @objc public func hasDisabledAskToAsk() -> Bool {
        return UserDefaults.standard.bool(forKey: DEFAULTS_ASKED_TO_PUSH)
    }

    // If notification were enabled by Leanplum's "Push Ask to Ask" or "Register For Push",
    // refreshPushPermissions will do the same registration for subsequent app sessions.
    // refreshPushPermissions is called by [Leanplum start].
    @objc public func refreshPushPermissions() {
        if UserDefaults.standard.bool(forKey: DEFAULTS_LEANPLUM_ENABLED_PUSH) {
            enableSystemPush()
        }
    }
    
    @objc public func notificationSettingsToRequestParams(_ settings: [AnyHashable: Any]) -> [AnyHashable: Any]? {
        guard let types = settings[LP_PARAM_DEVICE_USER_NOTIFICATION_TYPES], let categories = LPJSON.string(fromJSON:settings[LP_PARAM_DEVICE_USER_NOTIFICATION_CATEGORIES]) else {
            return nil
        }
        
        let params: [AnyHashable: Any] = [LP_PARAM_DEVICE_USER_NOTIFICATION_TYPES: types,
                                      LP_PARAM_DEVICE_USER_NOTIFICATION_CATEGORIES: categories]
        
        return params
    }
    
    func requireMessageContentWithMessageId(_ messageId: String, completionHandler: (() -> Void)? = nil) {
        Leanplum.onceVariablesChangedAndNoDownloadsPending {
            //LP_END_USER_CODE
            leanplumIncrementUserCodeBlock(-1)
            if VarCache.shared().messages()?[messageId] != nil {
                completionHandler?()
            } else {
                // Try downloading the messages again if it doesn't exist.
                // Maybe the message was created while the app was running.
                let request = LPRequestFactory.getVarsWithParams( [LP_PARAM_INCLUDE_DEFAULTS: NSNumber.init(booleanLiteral: false),
                                                                 LP_PARAM_INCLUDE_MESSAGE_ID: messageId]).andRequestType(.Immediate)
                
                request.onResponse { _ , response in
                    if let response = response as? [AnyHashable: Any?] {
                        let values = response[LP_KEY_VARS] as? [String: Any]
                        let messages = response[LP_KEY_MESSAGES] as? [String: Any]
                        let variants = response[LP_KEY_VARIANTS] as? [String]
                        let regions = response[LP_KEY_REGIONS] as? [String: Any]
                        let varsJson = ((response[LP_KEY_VARS] as? String) != nil) ? LPJSON.string(fromJSON: response[LP_KEY_VARS] ?? "") : nil
                        let varsSignature = response[LP_KEY_VARS_SIGNATURE] as? String
                        let localCaps = response[LP_KEY_LOCAL_CAPS] as? [[AnyHashable: Any]]
                        
                        VarCache.shared().applyVariableDiffs(values, messages: messages, variants: variants, localCaps: localCaps, regions: regions, variantDebugInfo: nil, varsJson: varsJson, varsSignature: varsSignature)
                        
                        completionHandler?()
                    }
                }
                
                LPRequestSender.sharedInstance().send(request)
            }
            //LP_BEGIN_USER_CODE
            leanplumIncrementUserCodeBlock(1)
        }
    }
}
