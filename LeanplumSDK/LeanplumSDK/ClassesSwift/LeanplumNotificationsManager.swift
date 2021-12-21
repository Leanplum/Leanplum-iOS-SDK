//
//  LeanplumNotificationsManager.swift
//  LeanplumSDK
//
//  Created by Nikola Zagorchev on 28.10.21.
//  Copyright © 2021 Leanplum. All rights reserved.

import Foundation

/// Manager responsible for handling push (remote) and local notifications
@objc public class LeanplumNotificationsManager: NSObject {
    
    // MARK: - Initialization
    @objc
    let proxy: LeanplumPushNotificationsProxy
    
    @objc public var shouldHandleNotificationBlock: LeanplumShouldHandleNotificationBlock?
    @objc public var isPushDeliveryTrackingEnabled = true
    
    private var notificationSettings: LeanplumNotificationSettings
    
    @objc
    public override init() {
        proxy = LeanplumPushNotificationsProxy()
        notificationSettings = LeanplumNotificationSettings()
        notificationSettings.setUp()
    }
    
    // MARK: - Notification Settings
    @objc public func updateNotificationSettings() {
        notificationSettings.updateSettings?()
    }
    
    @objc public func saveNotificationSettings(_ settings: [AnyHashable: Any]) {
        notificationSettings.save(settings)       
    }
    
    @objc public func removeNotificationSettings() {
        notificationSettings.removeSettings()
    }
    
    @objc public func getNotificationSettings(completionHandler: @escaping (_ settings: [AnyHashable: Any], _ areChanged: Bool)->()) {
        notificationSettings.getSettings(completionHandler: completionHandler)
    }
    
    @objc(didRegisterUserNotificationSettings:)
    public func didRegister(_ settings: UIUserNotificationSettings) {
        disableAskToAsk()
        notificationSettings.getSettings()
    }
    
    // MARK: - Push Token
    @objc public func didRegisterForRemoteNotificationsWithDeviceToken(_ deviceToken: Data) {
        disableAskToAsk()
        
        let formattedToken = getFormattedDeviceTokenFromData(deviceToken)
        
        var deviceAttributeParams: [AnyHashable: Any] = [:]
        
        let existingToken = self.pushToken()
        if existingToken == nil || existingToken != formattedToken {
            updatePushToken(formattedToken)
            deviceAttributeParams[LP_PARAM_DEVICE_PUSH_TOKEN] = formattedToken
        }
                
        notificationSettings.getSettings { [weak self] settings, areChanged in
            guard let self = self else { return }
            if areChanged {
                if let settings = self.notificationSettingsToRequestParams(settings) {
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
                        let requst = LPRequestFactory.setDeviceAttributesWithParams(deviceAttributeParams).andRequestType(.Immediate)
                        LPRequestSender.sharedInstance().send(requst)
                    }
                }
            }
        }
    }
    
    @objc public func didFailToRegisterForRemoteNotificationsWithError(_ error: Error) {
        disableAskToAsk()
        removePushToken()
    }
    
    // MARK: - Notification Actions
    // MARK: Notification Open
    @objc(notificationOpened:action:)
    func notificationOpened(userInfo: [AnyHashable : Any], action: String = LP_VALUE_DEFAULT_PUSH_ACTION) {
        guard let messageId = LeanplumUtils.messageIdFromUserInfo(userInfo) else { return }
        LeanplumUtils.lpLog(type: .debug, format: "Notification Opened MessageId: %@", messageId)
        
        let isDefaultAction = action == LP_VALUE_DEFAULT_PUSH_ACTION
        let actionName = isDefaultAction ? action : "iOS options.Custom actions.\(action)"
        
        let downloadFilesAndRunAction: (ActionContext) -> () = { context in
            context.maybeDownloadFiles()
            // Wait for Leanplum start so action responders are registered
            Leanplum.onStartIssued {
                context.runTrackedAction(name: actionName)
            }
        }
        
        if Leanplum.notificationsManager().areActionsEmbedded(userInfo) {
            var args:[AnyHashable : Any]
            if isDefaultAction {
                args = [action: userInfo[LP_KEY_PUSH_ACTION] ?? ""]
            } else {
                let customActions = userInfo[LP_KEY_PUSH_CUSTOM_ACTIONS] as? [AnyHashable : Any]
                // Arguments must be nested, so ActionContext.getChildArgs: resolves the action
                // ActionName is split by "." into components
                args = [
                    "iOS options": [
                        "Custom actions": [
                            action: customActions?[action]
                        ]
                    ]
                ]
            }
            let context = ActionContext.init(name: LP_PUSH_NOTIFICATION_ACTION, args: args, messageId: messageId)
            context.preventRealtimeUpdating = true
            downloadFilesAndRunAction(context)
        } else {
            requireMessageContentWithMessageId(messageId) {
                let context = Leanplum.createActionContext(forMessageId: messageId)
                downloadFilesAndRunAction(context)
            }
        }
    }
    
    // MARK: Notification Received
    func notificationReceived(userInfo: [AnyHashable : Any], isForeground: Bool) {
        guard let messageId = LeanplumUtils.messageIdFromUserInfo(userInfo) else { return }
        LeanplumUtils.lpLog(type: .debug, format: "Notification received - %@. MessageId: %@", isForeground ? "Foreground" : "Background", messageId)
        
        trackDelivery(userInfo: userInfo)
        if isForeground {
            if !Leanplum.notificationsManager().isMuted(userInfo) {
                showNotificationInForeground(userInfo: userInfo)
            }
        } else {
            if !Leanplum.notificationsManager().areActionsEmbedded(userInfo) {
                requireMessageContentWithMessageId(messageId)
            }
        }
    }
    
    func showNotificationInForeground(userInfo: [AnyHashable : Any]) {
        let openNotificationHandler = {
            self.notificationOpened(userInfo: userInfo)
        }
        
        // Execute custom block
        if let block = shouldHandleNotificationBlock {
            block(userInfo, openNotificationHandler)
            return
        }
        
        // Display the Notification as Confirm in-app message
        if let notifMessage = Leanplum.notificationsManager().getNotificationText(userInfo) {
            LPUIAlert.show(withTitle: LeanplumUtils.getAppName(), message: notifMessage, cancelButtonTitle: NSLocalizedString("Cancel", comment: ""), otherButtonTitles: [NSLocalizedString("View", comment: "")]) { buttonIndex in
                if buttonIndex == 1 {
                    openNotificationHandler()
                }
            }
        }
    }
    
    // MARK: - Delivery Tracking
    func trackDelivery(userInfo:[AnyHashable:Any]) {
        guard isPushDeliveryTrackingEnabled else {
            LeanplumUtils.lpLog(type: .debug, format: "Push delivery tracking is disabled")
            return
        }
        
        // We cannot consistently track delivery for local notifications
        // Do not track
        guard userInfo[LP_KEY_LOCAL_NOTIF] == nil else {
            return
        }
        
        var args = [String:Any]()
        args[LP_KEY_PUSH_METRIC_MESSAGE_ID] = LeanplumUtils.messageIdFromUserInfo(userInfo)
        args[LP_KEY_PUSH_METRIC_OCCURRENCE_ID] = userInfo[LP_KEY_PUSH_OCCURRENCE_ID]
        args[LP_KEY_PUSH_METRIC_SENT_TIME] = userInfo[LP_KEY_PUSH_SENT_TIME] ?? Date().timeIntervalSince1970
        args[LP_KEY_PUSH_METRIC_CHANNEL] = DEFAULT_PUSH_CHANNEL
        
        Leanplum.track(PUSH_DELIVERED_EVENT_NAME, params: args)
    }
}
