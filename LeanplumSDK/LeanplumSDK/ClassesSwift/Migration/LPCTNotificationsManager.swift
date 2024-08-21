//
//  LPCTNotificationsManager.swift
//  LeanplumSDK
//
//  Created by Nikola Zagorchev on 12.10.22.
//  Copyright © 2023 Leanplum. All rights reserved.

import Foundation
// Use @_implementationOnly to *not* expose CleverTapSDK to the Leanplum-Swift header
@_implementationOnly import CleverTapSDK

@objc public class LPCTNotificationsManager: NotificationsManager {
    // Using NSNumber since Optional Bool cannot be represented in Objective-C
    @objc public var openDeepLinksInForeground: NSNumber?
    @objc public var handleCleverTapNotificationBlock: LeanplumHandleCleverTapNotificationBlock?

    
    enum NotificationEvent: String, CustomStringConvertible {
        case opened = "Open"
        case received = "Receive"
        
        var description: String {
            rawValue
        }
    }
    
    override func notificationOpened(userInfo: [AnyHashable : Any], action: String = LP_VALUE_DEFAULT_PUSH_ACTION, fromLaunch: Bool = false) {
        if Utilities.messageIdFromUserInfo(userInfo) != nil {
            // Handle Leanplum notifications
            super.notificationOpened(userInfo: userInfo, action: action)
            return
        }
        // If the app is launched from notification and CT instance has already been created,
        // CT will handle the notification from their UIApplication didFinishLaunchingNotification observer
        if fromLaunch && MigrationManager.shared.hasLaunched {
            return
        }
        
        handleCleverTapNotification(userInfo: userInfo, event: .opened)
    }
    
    override func notificationReceived(userInfo: [AnyHashable : Any], isForeground: Bool) {
        if Utilities.messageIdFromUserInfo(userInfo) != nil {
            // Handle Leanplum notifications
            super.notificationReceived(userInfo: userInfo, isForeground: isForeground)
            return
        }
        handleCleverTapNotification(userInfo: userInfo, event: .received)
    }
    
    public override func didRegisterForRemoteNotificationsWithDeviceToken(_ deviceToken: Data) {
        super.didRegisterForRemoteNotificationsWithDeviceToken(deviceToken)
        
        handleWithCleverTapInstance {
            Log.debug("[Wrapper] Calling CleverTap.setPushToken for didRegisterForRemoteNotifications.")
            MigrationManager.shared.setPushToken(deviceToken)
        }
    }
    
    func handleCleverTapNotification(userInfo: [AnyHashable : Any], event: NotificationEvent) {
        let handleNotification:LeanplumCleverTapNotificationBlock = { openInForeground in
            self.handleWithCleverTapInstance {
                Log.info("""
                    [Wrapper] Calling CleverTap.handlePushNotification:openDeepLinksInForeground: \
                    \(openInForeground) for Push \(event)
                    """)
                CleverTap.handlePushNotification(userInfo, openDeepLinksInForeground: openInForeground)
            }
        }
        
        // Execute custom block
        if let block = self.handleCleverTapNotificationBlock {
            Log.info("[Wrapper] Calling custom handleCleverTapNotificationBlock")
            block(userInfo, event == .opened, handleNotification)
            return
        }
        
        // If `openDeepLinksInForeground` is not set explicitly, use `true` for notification Opens.
        handleNotification(openDeepLinksInForeground?.boolValue ?? (event == .opened))
    }
    
    @objc public func handleWithCleverTapInstance(action: @escaping () -> ()) {
        if MigrationManager.shared.hasLaunched {
            action()
        } else {
            // Leanplum.onStartIssued guarantees that Wrapper is initialized and CT instance is available, if migration has started.
            Leanplum.onStartIssued {
                if MigrationManager.shared.useCleverTap {
                    action()
                }
            }
        }
    }
}
