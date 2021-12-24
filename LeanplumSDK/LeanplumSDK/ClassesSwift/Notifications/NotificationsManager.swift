//
//  NotificationsManager.swift
//  LeanplumSDK
//
//  Created by Nikola Zagorchev on 28.10.21.
//  Copyright © 2021 Leanplum. All rights reserved.

import Foundation

/// Manager responsible for handling push (remote) and local notifications
@objc public class NotificationsManager: NSObject {
    
    // MARK: - Initialization
    @objc let proxy: NotificationsProxy
    
    @objc public var shouldHandleNotificationBlock: LeanplumShouldHandleNotificationBlock?
    @objc public var isPushDeliveryTrackingEnabled = true
    
    private var notificationSettings: NotificationSettings
    
    @objc
    public override init() {
        proxy = NotificationsProxy()
        notificationSettings = NotificationSettings()
    }
    
    // MARK: - Notification Settings
    @objc public func updateNotificationSettings() {
        notificationSettings.getSettings(updateToServer: true)
    }
    
    @objc public func saveNotificationSettings(_ settings: [AnyHashable: Any]) {
        notificationSettings.settings = settings
    }
    
    @objc public func removeNotificationSettings() {
        notificationSettings.settings = nil
    }
    
    @objc public func getNotificationSettings(completionHandler: @escaping (_ settings: [AnyHashable: Any], _ areChanged: Bool)->()) {
        notificationSettings.getSettings(completionHandler: completionHandler)
    }
    
    @objc(didRegisterUserNotificationSettings:)
    public func didRegister(_ settings: UIUserNotificationSettings) {
        isAskToAskDisabled = true
        notificationSettings.getSettings()
    }
    
    // MARK: - Push Token
    @objc public func didRegisterForRemoteNotificationsWithDeviceToken(_ deviceToken: Data) {
        isAskToAskDisabled = true
        
        let formattedToken = getFormattedDeviceTokenFromData(deviceToken)
        
        var deviceAttributeParams: [AnyHashable: Any] = [:]

        if pushToken != formattedToken {
            pushToken = formattedToken
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
                        let request = LPRequestFactory
                            .setDeviceAttributesWithParams(deviceAttributeParams)
                            .andRequestType(.Immediate)
                        LPRequestSender.sharedInstance().send(request)
                    }
                }
            }
        }
    }
    
    @objc public func didFailToRegisterForRemoteNotificationsWithError(_ error: Error) {
        isAskToAskDisabled = true
        pushToken = nil
    }
    
    // MARK: - Notification Actions
    // MARK: Notification Open
    @objc(notificationOpened:action:)
    func notificationOpened(userInfo: [AnyHashable: Any], action: String = LP_VALUE_DEFAULT_PUSH_ACTION) {
        guard let messageId = Utilities.messageIdFromUserInfo(userInfo) else {
            Log.debug("Push notification not handled, no message id found.")
            return
        }
        Log.debug("Notification Opened MessageId: \(messageId)")
        
        let isDefaultAction = action == LP_VALUE_DEFAULT_PUSH_ACTION
        
        let downloadFilesAndRunAction: (ActionContext) -> () = { context in
            context.maybeDownloadFiles()
            // Wait for Leanplum start so action responders are registered
            Leanplum.onStartIssued {
                context.runTrackedAction(name: action)
            }
        }
        
        if Leanplum.notificationsManager().areActionsEmbedded(userInfo) {
            var args: [AnyHashable: Any] = [:]
            if isDefaultAction {
                args[action] = userInfo[LP_KEY_PUSH_ACTION]
            } else {
                if let customActions = userInfo[LP_KEY_PUSH_CUSTOM_ACTIONS] as? [AnyHashable : Any] {
                    args[action] = customActions[action]
                }
            }
            let context: ActionContext = .init(name: LP_PUSH_NOTIFICATION_ACTION,
                                               args: args,
                                               messageId: messageId)
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
    func notificationReceived(userInfo: [AnyHashable: Any], isForeground: Bool) {
        guard let messageId = Utilities.messageIdFromUserInfo(userInfo) else { return }
        Log.debug("Notification received - \(isForeground ? "Foreground" : "Background"). MessageId: \(messageId)")
        
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
    
    func showNotificationInForeground(userInfo: [AnyHashable: Any]) {
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
            LPUIAlert.show(withTitle: Utilities.getAppName(),
                           message: notifMessage,
                           cancelButtonTitle: NSLocalizedString("Cancel", comment: ""),
                           otherButtonTitles: [NSLocalizedString("View", comment: "")]) { buttonIndex in
                if buttonIndex == 1 {
                    openNotificationHandler()
                }
            }
        }
    }
    
    // MARK: - Delivery Tracking
    func trackDelivery(userInfo: [AnyHashable: Any]) {
        guard isPushDeliveryTrackingEnabled else {
            Log.debug("Push delivery tracking is disabled")
            return
        }
        
        // We cannot consistently track delivery for local notifications
        // Do not track
        guard userInfo[LP_KEY_LOCAL_NOTIF] == nil else {
            return
        }
        
        var args = [String: Any]()
        args[LP_KEY_PUSH_METRIC_MESSAGE_ID] = Utilities.messageIdFromUserInfo(userInfo)
        args[LP_KEY_PUSH_METRIC_OCCURRENCE_ID] = userInfo[LP_KEY_PUSH_OCCURRENCE_ID]
        args[LP_KEY_PUSH_METRIC_SENT_TIME] = userInfo[LP_KEY_PUSH_SENT_TIME] ?? Date().timeIntervalSince1970
        args[LP_KEY_PUSH_METRIC_CHANNEL] = DEFAULT_PUSH_CHANNEL
        
        Leanplum.track(PUSH_DELIVERED_EVENT_NAME, params: args)
    }
}
