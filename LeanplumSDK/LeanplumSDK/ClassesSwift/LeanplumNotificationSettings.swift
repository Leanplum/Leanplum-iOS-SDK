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
                    if item.value == nil {
                        tmp[item.key] = NSNull()
                    } else {
                        tmp[item.key] = item.value
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
//            if areChanged { //TODO: do we care and do we need to save them???
//                self.updateSettings(newSettings: settings)
//            }
            self.currentSettings = settings
        }
    }
    
    private func updateSettings(newSettings: Dictionary<String, Any>) {
        
        //TODO: persist settings
//        updateSettingsToServer(settings: newSettings)
    }
    
    
    
    private func updateSettingsToServer(settings: Dictionary<String, Any>) {
        //TODO: create params add settings etc
//        let params: [String: Any] = [:]
//        let request = LPRequestFactory.setDeviceAttributesWithParams(params).andRequestType(.Immediate)//TODO: check if immediate
//        LPRequestSender.sharedInstance().send(request)
    }
    
    private func checkIfSettingsAreChanged(newSettings: Dictionary<String, Any>) -> Bool {
        return true
    }
    
    @available(iOS 10.0, *)
    private func getSettingsFromUserNotification(completionHandler: @escaping (_ settings: Dictionary<String, Any?>)->()) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            let types = settings.toInt()
            
            UNUserNotificationCenter.current().getNotificationCategories { categories in
                var cate: [UNNotificationCategory] = []
                for category in categories {
//                    category.identifier do the logic
//                        if category.identifier != nil {
                        cate.append(category)
//                        }
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
