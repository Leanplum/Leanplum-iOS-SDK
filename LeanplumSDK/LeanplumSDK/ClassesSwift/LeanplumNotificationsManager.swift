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
    
    @objc public override init() {
        proxy = LeanplumPushNotificationsProxy()
    }
    
    @objc(notificationOpened:action:)
    func notificationOpened(userInfo: [AnyHashable : Any], action: String = LP_VALUE_DEFAULT_PUSH_ACTION) {
        LeanplumUtils.lpLog(type: .debug, format: "Notification Opened Id: %@", LeanplumUtils.getNotificationId(userInfo))
        
        guard let messageId = LeanplumUtils.messageIdFromUserInfo(userInfo) else { return }
        
        let actionName = action == LP_VALUE_DEFAULT_PUSH_ACTION ? action : "iOS options.Custom actions.\(action)"

        var context:ActionContext
        if LeanplumUtils.areActionsEmbedded(userInfo) {
            let args = [LP_VALUE_DEFAULT_PUSH_ACTION : userInfo[LP_KEY_PUSH_ACTION]]
            context = ActionContext.init(name: LP_PUSH_NOTIFICATION_ACTION, args: args as [AnyHashable : Any], messageId: messageId)
            context.preventRealtimeUpdating = true
        } else {
            // TODO: check if the message exists or needs FCU
            context = Leanplum.createActionContext(forMessageId: messageId)
        }
        context.maybeDownloadFiles()
        // Wait for Leanplum start so action responders are registered
        Leanplum.onStartIssued {
            context.runTrackedAction(name: actionName)
        }
    }
    
    func notificationReceived(userInfo: [AnyHashable : Any], isForeground: Bool) {
        guard let messageId = LeanplumUtils.messageIdFromUserInfo(userInfo) else { return }
        LeanplumUtils.lpLog(type: .debug, format: "Notification received on %@. MessageId: @%, Id: %@", isForeground ? "Foreground" : "Background", messageId, LeanplumUtils.getNotificationId(userInfo))
        
        if isForeground {
            if !LeanplumUtils.isMuted(userInfo) {
                showNotificationInForeground(userInfo: userInfo)
            }
        } else {
            if !LeanplumUtils.areActionsEmbedded(userInfo) {
                // TODO: check if notification action is not embedded and needs FCU / Prefetch
            }
        }
    }
    
    func showNotificationInForeground(userInfo: [AnyHashable : Any]) {
        // Execute custom block
        if let block = Leanplum.pushSetupBlock() {
            block()
            return
        }
        
        // Display the Notification as Confirm in-app message
        if let notifMessage = LeanplumUtils.getNotificationText(userInfo) {
            LPUIAlert.show(withTitle: LeanplumUtils.getAppName(), message: notifMessage, cancelButtonTitle: NSLocalizedString("Cancel", comment: ""), otherButtonTitles: [NSLocalizedString("View", comment: "")]) { buttonIndex in
                if buttonIndex == 1 {
                    self.notificationOpened(userInfo: userInfo)
                }
            }
        }
    }
}
