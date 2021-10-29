//
//  LeanplumNotificationSettings.swift
//  LeanplumSDK
//
//  Copyright (c) 2021 Leanplum, Inc. All rights reserved.
//

import Foundation

public class LeanplumNotificationSettings: NSObject {

    @objc public var currentSettings: Dictionary<String, Any> = [:]
    @objc public var updateSettings: (() -> Void)?
    
    @objc public func setUp() {
        loadSettings()
        updateSettings = { [weak self] in
            self?.loadSettings()
        }
    }
    
    private func getSettigs(completionHandler: @escaping (_ settings: Dictionary<String, Any>)->()) {
        if #available(iOS 10.0, *) {
            self.getSettingsFromUserNotification { settings in
                var tmp: [String: Any] = [:]
                for item in settings {
                    if let value = item.value {
                        tmp[item.key] = value
                    } else {
                        tmp[item.key] = NSNull()
                    }
                }
                completionHandler(tmp)
            }
        } else {
            // Fallback on earlier versions
            completionHandler(getSettingsFromUIApplication())
        }
    }
    
    private func loadSettings() {
        getSettigs { [weak self] settings in
            guard let self = self else { return }
            if self.checkIfSettingsAreChanged(newSettings: settings) { //TODO: do we care and do we need to save them???
                self.updateSettings(newSettings: settings)
                self.currentSettings = settings //TODO: potential issue: check case: value is nil for type??
            }
        }
    }
    
    private func updateSettings(newSettings: Dictionary<String, Any>) {
        UserDefaults.standard.setValue(newSettings, forKey: self.leanplumUserNotificationSettingsKey())
        //TODO: update settings to server
//        updateSettingsToServer(settings: newSettings)
    }
    
    
    
    private func updateSettingsToServer(settings: Dictionary<String, Any>) {
        //TODO: create params add settings etc
//        let params: [String: Any] = [:]
//        let request = LPRequestFactory.setDeviceAttributesWithParams(params).andRequestType(.Immediate)//TODO: check if immediate
//        LPRequestSender.sharedInstance().send(request)
        
        Leanplum.onStartResponse { success in
            if success {
                //update here
            }
        }
    }
    
    private func checkIfSettingsAreChanged(newSettings: Dictionary<String, Any>) -> Bool {
        //TODO: compare with saved dictionary
        if let savedSettings = UserDefaults.standard.dictionary(forKey: self.leanplumUserNotificationSettingsKey()), NSDictionary(dictionary: savedSettings).isEqual(to: NSDictionary(dictionary: currentSettings) as! [AnyHashable : Any] ) {
            //TODO: fix !
            return true
        }
        return false
    }
    
    private func leanplumUserNotificationSettingsKey() -> String {
        return String(format: LEANPLUM_DEFAULTS_USER_NOTIFICATION_SETTINGS_KEY, LPAPIConfig.shared().appId, LPAPIConfig.shared().userId, [LPAPIConfig.shared().deviceId])
    }
    
    @available(iOS 10.0, *)
    private func getSettingsFromUserNotification(completionHandler: @escaping (_ settings: Dictionary<String, Any?>)->()) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            let types = settings.toInt()
            
            UNUserNotificationCenter.current().getNotificationCategories { categories in
                var cate: [UNNotificationCategory] = []
                for category in categories {
                    cate.append(category)
                }
                let sortedCategories = cate.sorted { (lhs: UNNotificationCategory, rhs: UNNotificationCategory) -> Bool in
                    return lhs.identifier.caseInsensitiveCompare(rhs.identifier) == .orderedAscending
                }
                
                let settings = [
                    LP_PARAM_DEVICE_USER_NOTIFICATION_TYPES: types,
                    LP_PARAM_DEVICE_USER_NOTIFICATION_CATEGORIES: sortedCategories
                ] as [String : Any?]
                completionHandler(settings)
            }
        }
    }
    
    //Get settings for os befor iOS 10
    private func getSettingsFromUIApplication() -> Dictionary<String, Any> {
        guard let settings = UIApplication.shared.currentUserNotificationSettings?.dictionary else {
            return [:]
        }
        return settings
    }
}

//TODO: this should go into manager
extension LeanplumPushNotificationUtils {
    //
    func didRegisterForRemoteNotificationsWithDeviceToken(_ deviceToken: Data) {
        let formattedToken = LeanplumPushNotificationUtils.getFormattedDeviceTokenFromData(deviceToken)
        
        let deviceAttributeParams: NSMutableDictionary = NSMutableDictionary()
        if let existingToken = LeanplumPushNotificationUtils.pushToken() {
            if existingToken == "" || existingToken != formattedToken {
                LeanplumPushNotificationUtils.savePushToken(formattedToken)
                deviceAttributeParams[LP_PARAM_DEVICE_PUSH_TOKEN] = formattedToken
            }
        } else {
            LeanplumPushNotificationUtils.savePushToken(formattedToken)
            deviceAttributeParams[LP_PARAM_DEVICE_PUSH_TOKEN] = formattedToken
        }
        
        //TODO: move notificationSettings instance into manager
        //TODO: add chack if they are changed from before
        let settings = LPInternalState.shared().notificationSettings.currentSettings
        //TODO: refactor addEntries directly in [AnyHashable: Any] avaid using NSMutableDictionary
        deviceAttributeParams.addEntries(from: LPNetworkEngine.notificationSettings(toRequestParams: settings))
        
        if let deviceAttributeParams = deviceAttributeParams as? [AnyHashable: Any], deviceAttributeParams.isEmpty {
            Leanplum.onStartResponse { success in
                if success {
                    let requst = LPRequestFactory.setDeviceAttributesWithParams(deviceAttributeParams)
                    LPRequestSender.sharedInstance().send(requst)
                }
            }
        }
    }
    
    func didFailToRegisterForRemoteNotificationsWithError(_ error: Error) {
//        [self leanplum_disableAskToAsk];
        LeanplumPushNotificationUtils.removePushToken()
    }
}
