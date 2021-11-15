//
//  LeanplumNotificationsManager.swift
//  LeanplumSDK
//
//  Created by Nikola Zagorchev on 28.10.21.
//  Copyright © 2021 Leanplum. All rights reserved.

import Foundation

/// Manager responsible for handling push (remote) and local notifications
@objc public class LeanplumNotificationsManager: NSObject {
    
    @objc public var proxy: LeanplumPushNotificationsProxy
    private var notificationSettings: LeanplumNotificationSettings
    
    @objc public override init() {
        proxy = LeanplumPushNotificationsProxy()
        notificationSettings = LeanplumNotificationSettings()
        notificationSettings.setUp()
    }
    
    @objc public func updateNotificaitonSettings() {
        notificationSettings.updateSettings?()
    }
    
    @objc public func getNotificationSettings(completionHandler: @escaping (_ settings: [AnyHashable: Any], _ areChanged: Bool)->()) {
        notificationSettings.getSettings(completionHandler: completionHandler)
    }
    
    @objc public func didRegisterForRemoteNotificationsWithDeviceToken(_ deviceToken: Data) {
        LeanplumPushNotificationUtils.disableAskToAsk()
        
        let formattedToken = LeanplumPushNotificationUtils.getFormattedDeviceTokenFromData(deviceToken)
        
        var deviceAttributeParams: [AnyHashable: Any] = [:]
        if let existingToken = LeanplumPushNotificationUtils.pushToken() {
            if existingToken != formattedToken {
                LeanplumPushNotificationUtils.savePushToken(formattedToken)
                deviceAttributeParams[LP_PARAM_DEVICE_PUSH_TOKEN] = formattedToken
            }
        } else {
            LeanplumPushNotificationUtils.savePushToken(formattedToken)
            deviceAttributeParams[LP_PARAM_DEVICE_PUSH_TOKEN] = formattedToken
        }
        
        notificationSettings.getSettings { [weak self] settings, areChanged in
            guard let self = self else { return }
            if areChanged {
                if let settings = self.notificationSettings.toRequestParams() {
                    let result = Array(settings.keys).reduce(deviceAttributeParams) { (dict, key) -> [AnyHashable: Any] in
                        var dict = dict
                        dict[key] = settings[key] as Any?
                        return dict
                    }
                    deviceAttributeParams = result
                }
            }
            
            if !deviceAttributeParams.isEmpty {
                Leanplum.onStartResponse { success in
                    if success {
                        let requst = LPRequestFactory.setDeviceAttributesWithParams(deviceAttributeParams)
                        LPRequestSender.sharedInstance().send(requst)
                    }
                }
            }
        }
    }
    
    @objc public func didFailToRegisterForRemoteNotificationsWithError(_ error: Error) {
        LeanplumPushNotificationUtils.disableAskToAsk()
        LeanplumPushNotificationUtils.removePushToken()
    }
}
