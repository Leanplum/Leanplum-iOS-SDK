//
//  LeanplumNotificationSettings.swift
//  LeanplumSDK
//
//  Copyright (c) 2021 Leanplum, Inc. All rights reserved.
//

import Foundation

class LeanplumNotificationSettings {

    var currentSettings: [AnyHashable: Any] = [:]
    var updateSettings: (() -> Void)?
    
    func setUp() {
//        loadSettings()
        updateSettings = { [weak self] in
            self?.loadSettings()
        }
    }
    
    func toRequestParams() -> [AnyHashable: Any]? {//TODO: move into Utils?
        guard !currentSettings.isEmpty, let types = currentSettings[LP_PARAM_DEVICE_USER_NOTIFICATION_TYPES], let categories = LPJSON.string(fromJSON:currentSettings[LP_PARAM_DEVICE_USER_NOTIFICATION_CATEGORIES]) else {
            return nil
        }
        
        let params: [AnyHashable: Any] = [LP_PARAM_DEVICE_USER_NOTIFICATION_TYPES: types,
                                      LP_PARAM_DEVICE_USER_NOTIFICATION_CATEGORIES: categories]
        
        return params
    }
    
    func getSettings(completionHandler: @escaping (_ settings: [AnyHashable: Any], _ areChanged: Bool)->()) {
        if #available(iOS 10.0, *) {
            self.getSettingsFromUserNotification { [weak self] settings in
                guard let self = self else {
                    completionHandler([:], false)
                    return
                }
                var settings_: [AnyHashable: Any] = [:]
                for item in settings {
                    settings_[item.key] = item.value != nil ? item.value : NSNull()
                }
                let changed = self.checkIfSettingsAreChanged(newSettings: settings_)
                completionHandler(settings_, changed)
            }
        } else {
            // Fallback on earlier versions
            let settings = getSettingsFromUIApplication()
            let changed = checkIfSettingsAreChanged(newSettings: settings)
            completionHandler(settings, changed)
        }
    }
    
    private func loadSettings() {//TODO: remnam to update or something
        guard let key = self.leanplumUserNotificationSettingsKey() else {
            return
        }
        if let savedSettings = UserDefaults.standard.dictionary(forKey: key) {
            currentSettings = savedSettings
        }
        getSettings { [weak self] settings, areChanged in
            guard let self = self else { return }
            if areChanged {
                self.currentSettings = settings //TODO: potential issue: check case: value is nil for type??
                self.saveSettings()
                //update settings to server
                self.updateSettingsToServer()
            }
        }
    }
    
    private func saveSettings() {
        guard let key = self.leanplumUserNotificationSettingsKey() else {
            return
        }
        UserDefaults.standard.setValue(currentSettings, forKey: key)
    }
    
    
    
    private func updateSettingsToServer() {
        //TODO: create params add settings etc
        if let params = self.toRequestParams() {
            Leanplum.onStartResponse { success in
                if success {
                    //update here
                    let request = LPRequestFactory.setDeviceAttributesWithParams(params).andRequestType(.Immediate)//TODO: check if immediate
                    LPRequestSender.sharedInstance().send(request)
                }
            }
        }
    }
    
    private func checkIfSettingsAreChanged(newSettings: [AnyHashable: Any]) -> Bool {
        guard let key = self.leanplumUserNotificationSettingsKey() else {
            return false //TODO: false or true???
        }
        if let savedSettings = UserDefaults.standard.dictionary(forKey: key), NSDictionary(dictionary: savedSettings).isEqual(to: newSettings) {
            return false
        }
        return true
    }
    
    private func leanplumUserNotificationSettingsKey() -> String? {
        guard let appId = LPAPIConfig.shared().appId, let userId = LPAPIConfig.shared().userId, let deviceId = LPAPIConfig.shared().deviceId else {
            return nil
        }
        return String(format: LEANPLUM_DEFAULTS_USER_NOTIFICATION_SETTINGS_KEY, appId, userId, deviceId)
    }
    
    @available(iOS 10.0, *)
    private func getSettingsFromUserNotification(completionHandler: @escaping (_ settings: [AnyHashable: Any?])->()) {
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
                ] as [AnyHashable : Any?]
                completionHandler(settings)
            }
        }
    }
    
    //Get settings for os befor iOS 10
    private func getSettingsFromUIApplication() -> [AnyHashable: Any] {
        guard let settings = UIApplication.shared.currentUserNotificationSettings?.dictionary else {
            return [:]
        }
        return settings
    }
}
