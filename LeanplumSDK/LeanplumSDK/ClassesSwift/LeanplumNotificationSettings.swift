//
//  LeanplumNotificationSettings.swift
//  LeanplumSDK
//
//  Copyright (c) 2021 Leanplum, Inc. All rights reserved.
//

import Foundation

class LeanplumNotificationSettings {
    
    func getSettings(updateToServer: Bool = false, completionHandler: ((_ settings: [AnyHashable: Any], _ areChanged: Bool)->())? = nil) {
        if #available(iOS 10.0, *) {
            self.getSettingsFromUserNotification { [weak self] settings in
                guard let self = self else {
                    completionHandler?([:], false)
                    return
                }
                var settings_: [AnyHashable: Any] = [:]
                for item in settings {
                    settings_[item.key] = item.value != nil ? item.value : nil
                }
                let changed = self.checkIfSettingsAreChanged(newSettings: settings_)
                if changed {
                    self.updateSettings(settings_, updateToServer: updateToServer)
                }
                completionHandler?(settings_, changed)
            }
        } else {
            // Fallback on earlier versions
            let settings = getSettingsFromUIApplication()
            let changed = checkIfSettingsAreChanged(newSettings: settings)
            if changed {
                updateSettings(settings, updateToServer: updateToServer)
            }
            completionHandler?(settings, changed)
        }
    }
    
    func save(_ settings: [AnyHashable: Any]) {
        guard let key = self.leanplumUserNotificationSettingsKey() else {
            return
        }
        UserDefaults.standard.setValue(settings, forKey: key)
    }
    
    func removeSettings() {
        guard let key = self.leanplumUserNotificationSettingsKey() else {
            return
        }
        UserDefaults.standard.removeObject(forKey: key)
    }
    
    private func updateSettings(_ settings: [AnyHashable: Any], updateToServer: Bool) {
        save(settings)
        if updateToServer {
            updateSettingsToServer(settings)
        }
    }
    
    private func updateSettingsToServer(_ settings: [AnyHashable: Any]) {
        if let params = Leanplum.notificationsManager().notificationSettingsToRequestParams(settings) {
            Leanplum.onStartResponse { success in
                if success {
                    var deviceAttributesWithParams: [AnyHashable: Any] = params
                    if let pushToken = Leanplum.notificationsManager().pushToken() {
                        deviceAttributesWithParams[LP_PARAM_DEVICE_PUSH_TOKEN] = pushToken
                    }
                    let request = LPRequestFactory.setDeviceAttributesWithParams(deviceAttributesWithParams).andRequestType(.Immediate)
                    LPRequestSender.sharedInstance().send(request)
                }
            }
        }
    }
    
    private func checkIfSettingsAreChanged(newSettings: [AnyHashable: Any]) -> Bool {
        guard let key = self.leanplumUserNotificationSettingsKey() else {
            return true
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
                var cate: [String] = []
                for category in categories {
                    cate.append(category.identifier)
                }
                let sortedCategories = cate.sorted { (lhs: String, rhs: String) -> Bool in
                    return lhs.caseInsensitiveCompare(rhs) == .orderedAscending
                }
                
                let settings = [
                    LP_PARAM_DEVICE_USER_NOTIFICATION_TYPES: types,
                    LP_PARAM_DEVICE_USER_NOTIFICATION_CATEGORIES: sortedCategories
                ] as [AnyHashable : Any?]
                completionHandler(settings)
            }
        }
    }
    
    /**
     * Retrieves notification settings from UIApplication
     * Used for iOS 9 devices (older than iOS 10)
     */
    private func getSettingsFromUIApplication() -> [AnyHashable: Any] {
        guard let settings = UIApplication.shared.currentUserNotificationSettings?.dictionary else {
            return [:]
        }
        return settings
    }
}