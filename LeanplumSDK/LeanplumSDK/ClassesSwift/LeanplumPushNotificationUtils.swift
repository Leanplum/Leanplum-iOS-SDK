//
//  LeanplumPushNotificationUtils.swift
//  LeanplumSDK
//
//  Created by Nikola Zagorchev on 20.09.21.
//

import Foundation

public class LeanplumPushNotificationUtils: NSObject {
    
    static func getFormattedDeviceTokenFromData(_ token: Data) -> String {
        var formattedToken = token.hexEncodedString()
        formattedToken = formattedToken.replacingOccurrences(of: "<", with: "")
            .replacingOccurrences(of: ">", with: "")
            .replacingOccurrences(of: " ", with: "")
        return formattedToken
    }
    
    @objc static public func enableSystemPush() {
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
                    print("Error: \(error)")
                }
                
                if granted {
                    DispatchQueue.main.async {
                        UIApplication.shared.registerForRemoteNotifications()
                    }
                }
            }
        } else if #available(iOS 8.0, *) {
            UIApplication.shared.registerUserNotificationSettings(UIUserNotificationSettings(types: [.badge, .sound, .alert],
                                                                                             categories: nil))
            UIApplication.shared.registerForRemoteNotifications()
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
    
    static func pushToken() -> String? {
        //return push token from defaults
        return UserDefaults.standard.string(forKey: LeanplumPushNotificationUtils.pushTokenKey())
    }
    
    static func savePushToken(_ token: String) {
        UserDefaults.standard.setValue(token, forKey: LeanplumPushNotificationUtils.pushTokenKey())
    }
    
    private static func pushTokenKey() -> String {
        //TODO: check if some of the values is nil
        return String(format: LEANPLUM_DEFAULTS_PUSH_TOKEN_KEY, LPAPIConfig.shared().appId, LPAPIConfig.shared().userId, [LPAPIConfig.shared().deviceId])
    }
    
    static func removePushToken() {
        UserDefaults.standard.removeObject(forKey: LeanplumPushNotificationUtils.pushTokenKey())
    }
    
    @objc public static func isPushEnabled() -> Bool {
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
    
    @objc public static func disableAskToAsk() {
        UserDefaults.standard.setValue(true, forKey: DEFAULTS_ASKED_TO_PUSH)
    }
    
    @objc public static func hasDisabledAskToAsk() -> Bool {
        return UserDefaults.standard.bool(forKey: DEFAULTS_LEANPLUM_ENABLED_PUSH)
    }

    @objc public static func refreshPushPermissions() {
        if UserDefaults.standard.bool(forKey: DEFAULTS_LEANPLUM_ENABLED_PUSH) {
            LeanplumPushNotificationUtils.enableSystemPush()
        }
    }
    
    func requireMessageContentWithMessageId(_ messageId: String, completionHandler: @escaping () -> Void) {
        Leanplum.onceVariablesChangedAndNoDownloadsPending {
            //LP_END_USER_CODE
            leanplumIncrementUserCodeBlock(-1)
            if VarCache.shared().messages()?[messageId] != nil {
                completionHandler()
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
                        
                        completionHandler()
                    }
                }
                
                LPRequestSender.sharedInstance().send(request)
            }
            //LP_BEGIN_USER_CODE
            leanplumIncrementUserCodeBlock(1)
        }
    }
}





