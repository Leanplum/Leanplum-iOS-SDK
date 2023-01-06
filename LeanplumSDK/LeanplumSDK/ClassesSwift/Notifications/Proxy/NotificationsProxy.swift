//
//  NotificationsProxy.swift
//  Leanplum-iOS-SDK
//
//  Created by Nikola Zagorchev on 29.09.21.
//  Copyright © 2022 Leanplum. All rights reserved.

import Foundation
import UIKit

public class NotificationsProxy: NSObject {
    // MARK: - Initialization
    internal override init() {}
    
    /// TimeInterval when application was resumed
    /// Used for iOS 9 notifications when state changes from inactive to active
    @objc public var resumedTimeInterval: Double = 0
    
    lazy var appDelegate = UIApplication.shared.delegate
    lazy var appDelegateClass: AnyClass? = object_getClass(appDelegate)
    lazy var userNotificationCenterDelegateClass: AnyClass? = appDelegateClass
    
    var pushNotificationBackgroundFetchResult: UIBackgroundFetchResult = .newData
    var isCustomAppDelegateUsed = false
    
    private var pushNotificationPresentationOptionWrapper: Any?
    @objc @available(iOS 10.0, *)
    // UNNotificationPresentationOptionNone
    public var pushNotificationPresentationOption: UNNotificationPresentationOptions {
        get {
            if let value = pushNotificationPresentationOptionWrapper as? UNNotificationPresentationOptions {
                return value
            }
            return []
        }
        set { pushNotificationPresentationOptionWrapper = newValue }
    }
    
    let userNotificationDelegateName = "UNUserNotificationCenterDelegate"
    
    var swizzled = Swizzled()

    var hasImplementedNotificationCenterMethods = false
    private(set) var shouldFallbackToLegacyMethods = false
    
    private(set) var notificationOpenedFromStart = false
    private(set) var notificationHandledFromStart: [AnyHashable:Any]?
    
    // MARK: - Application didFinishLaunching
    @objc public func addDidFinishLaunchingObserver() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(leanplum_applicationDidFinishLaunching(notification:)),
                                               name: UIApplication.didFinishLaunchingNotification, object: nil)
    }
    
    @objc public func removeDidFinishLaunchingObserver() {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func leanplum_applicationDidFinishLaunching(notification: Notification) {
        Log.debug("Called leanplum_applicationDidFinishLaunching: \(notification.userInfo ?? [:]), state \(UIApplication.shared.applicationState.rawValue))")
        
        if let userInfo = notification.userInfo {
            applicationLaunched(launchOptions: userInfo)
        }
    }
    
    func applicationLaunched(launchOptions: [AnyHashable: Any]) {
        if let remoteNotification = launchOptions[UIApplication.LaunchOptionsKey.remoteNotification] as? [AnyHashable: Any] {
            Log.info("Application Launched with notification: \(remoteNotification)")
            notificationHandledFromStart = remoteNotification
            
            // started in background, woken up by remote notification
            if UIApplication.shared.applicationState == .background {
                notificationOpenedFromStart = false
                Leanplum.notificationsManager().notificationReceived(userInfo: remoteNotification, isForeground: false)
            } else {
                notificationOpenedFromStart = true
                Leanplum.notificationsManager().notificationOpened(userInfo: remoteNotification, action: LP_VALUE_DEFAULT_PUSH_ACTION, fromLaunch: true)
            }
        } else if
            let localNotification =
                    launchOptions[UIApplication.LaunchOptionsKey.localNotification] as? UILocalNotification,
                let userInfo = localNotification.userInfo {
            notificationHandledFromStart = userInfo
            notificationOpenedFromStart = true
            Leanplum.notificationsManager().notificationOpened(userInfo: userInfo)
        }
    }

    // MARK: - Swizzle Methods
    /// Swizzling Entry point
    @objc public func setupNotificationSwizzling() {
        guard LPUtils.isSwizzlingEnabled() else {
            Log.info("Method swizzling is disabled, make sure to manually call Leanplum methods.")
            return
        }
        
        guard !swizzled.once else {
            return
        }
        
        swizzled.once = true
        
        if !isCustomAppDelegateUsed {
            ensureOriginalAppDelegate()
        }
        
        // Token methods are version agnostic
        swizzleTokenMethods()
        
        // Try to swizzle UNUserNotificationCenterDelegate methods
        if #available(iOS 10.0, *) {
            // Client's UNUserNotificationCenter delegate needs to be set before Leanplum starts
            swizzleUNUserNotificationCenterMethods()
            swizzleApplicationDidReceiveFetchCompletionHandler()
            if !swizzled.applicationDidReceiveRemoteNotificationWithCompletionHandler {
                // if background modes / content-available:1, swizzle for prefetch
                swizzleApplicationDidReceiveFetchCompletionHandler(true)
            } else if !hasImplementedNotificationCenterMethods {
                // application:didReceiveRemoteNotification:fetchCompletionHandler: method is implemented and
                // notificationCenter methods are not, we need to call that method manually,
                // since we set our own notification center delegate
                shouldFallbackToLegacyMethods = true
            }
        } else {
            swizzleUserNotificationSettings()
            swizzleLocalNotificationMethods()
            
            swizzleApplicationDidReceiveFetchCompletionHandler()
            if !swizzled.applicationDidReceiveRemoteNotificationWithCompletionHandler {
                // if it is not swizzled, add an implementation to listen for notifications
                swizzleApplicationDidReceiveFetchCompletionHandler(true)
                if hasImplementedApplicationDidReceive() {
                    // need to call legacy
                    shouldFallbackToLegacyMethods = true
                }
            }
        }
    }
}
