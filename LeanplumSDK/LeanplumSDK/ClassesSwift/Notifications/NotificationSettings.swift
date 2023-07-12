//
//  NotificationSettings.swift
//  LeanplumSDK
//
//  Copyright (c) 2021 Leanplum, Inc. All rights reserved.
//

import Foundation

class NotificationSettings {

    func getSettings(updateToServer: Bool = false, completionHandler: ((_ settings: [AnyHashable: Any], _ areChanged: Bool)->())? = nil) {
        self.getSettingsFromUserNotification { [weak self] settings in
            guard let self = self else {
                completionHandler?([:], false)
                return
            }
            var settings_: [AnyHashable: Any] = [:]
            for item in settings {
                settings_[item.key] = item.value != nil ? item.value : nil
            }
            let changed = !settings_.isEqual(Leanplum.user.notificationSettings ?? [:])
            if changed {
                self.updateSettings(settings_, updateToServer: updateToServer)
            }
            completionHandler?(settings_, changed)
        }
    }
    
    private func updateSettings(_ settings: [AnyHashable: Any], updateToServer: Bool) {
        Leanplum.user.notificationSettings = settings
        if updateToServer {
            if let params = Leanplum.notificationsManager().notificationSettingsToRequestParams(settings) {
                Leanplum.onStartResponse { success in
                    if success {
                        var deviceAttributesWithParams: [AnyHashable: Any] = params
                        if let pushToken = Leanplum.user.pushToken {
                            deviceAttributesWithParams[LP_PARAM_DEVICE_PUSH_TOKEN] = pushToken
                        }
                        let request = LPRequestFactory.setDeviceAttributesWithParams(deviceAttributesWithParams).andRequestType(.Immediate)
                        LPRequestSender.sharedInstance().send(request)
                    }
                }
            }
        }
    }

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
}
