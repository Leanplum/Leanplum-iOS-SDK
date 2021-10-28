//
//  LeanplumPushNotificationsProxy.swift
//  Leanplum-iOS-SDK
//
//  Created by Nikola Zagorchev on 29.09.21.
//  Copyright © 2021 Leanplum. All rights reserved.

import Foundation
import UIKit

public class LeanplumPushNotificationsProxy: NSObject {
    
    internal override init() {}
    
    @objc public var deviceVersion:String?
    @objc public var resumedTimeInterval:Double = 0
    
    lazy var appDelegate = UIApplication.shared.delegate
    lazy var appDelegateClass: AnyClass? = object_getClass(appDelegate)
    lazy var userNotificationCenterDelegateClass: AnyClass? = appDelegateClass
    
    var application: UIApplication = UIApplication.shared
    
    var pushNotificationBackgroundFetchResult:UIBackgroundFetchResult = .newData
    
    @available(iOS 10.0, *)
    lazy var pushNotificationPresentationOption:UNNotificationPresentationOptions = [] // UNNotificationPresentationOptionNone
    
    private(set) var swizzledApplicationDidRegisterRemoteNotifications = false
    private(set) var swizzledApplicationDidFailToRegisterForRemoteNotificationsWithError = false
    
    private(set) var swizzledApplicationDidReceiveRemoteNotificationWithCompletionHandler = false
    
    private(set) var swizzledUserNotificationCenterDidReceiveNotificationResponseWithCompletionHandler = false
    private(set) var swizzledUserNotificationCenterWillPresentNotificationWithCompletionHandler = false
    
    private(set) var swizzledApplicationDidReceiveLocalNotification = false
    
    private(set) var swizzledApplicationDidRegisterUserNotificationSettings = false
    
    private(set) var notificationOpenedFromStart = false
    private(set) var notificationHandledFromStart:[AnyHashable:Any]?
    
    private(set) var hasImplementedNotifCenterMethods = false
    private(set) var shouldFallbackToLegacyMethods = false
    
    let userNotificationDelegateName = "UNUserNotificationCenterDelegate"
    
    @objc public func addDidFinishLaunchingObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(leanplum_applicationDidFinishLaunching(notification:)), name: UIApplication.didFinishLaunchingNotification, object: nil)
    }
    
    @objc public func removeDidFinishLaunchingObserver() {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func leanplum_applicationDidFinishLaunching(notification: Notification) {
        LeanplumUtils.lpLog(type: .debug, format: "Called leanplum_applicationDidFinishLaunching: %@, state %d", notification.userInfo ?? [:], UIApplication.shared.applicationState.rawValue)
        
        if let userInfo = notification.userInfo {
            self.leanplum_applicationDidFinishLaunching(launchOptions: userInfo)
        }
    }
    
    private func leanplum_applicationDidFinishLaunching(launchOptions: [AnyHashable:Any]) {
        if let remoteNotif = launchOptions[UIApplication.LaunchOptionsKey.remoteNotification] as? [AnyHashable : Any] {
            self.notificationHandledFromStart = remoteNotif
            
            // started in background, woken up by remote notification
            if UIApplication.shared.applicationState == .background {
                notificationOpenedFromStart = false
                notificationReceived(userInfo: remoteNotif, isForeground: false)
            } else {
                notificationOpenedFromStart = true
                notificationOpened(userInfo: remoteNotif)
            }
        } else if let localNotif = launchOptions[UIApplication.LaunchOptionsKey.localNotification] as? UILocalNotification,
                  let userInfo = localNotif.userInfo {
            notificationOpened(userInfo: userInfo)
        }
    }
    
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
    
    func isEqualToHandledNotification(userInfo: [AnyHashable : Any]) -> Bool {
        if let fromStart = notificationHandledFromStart {
            let idA = LeanplumUtils.getNotificationId(fromStart)
            let idB = LeanplumUtils.getNotificationId(userInfo)
            return idA == idB
        }
        
        return false
    }
    
    func isIOSVersionGreaterThanOrEqual(_ version:String) -> Bool {
        let currentVersion = UIDevice.current.systemVersion
        return (deviceVersion ?? currentVersion).compare(version,options: .numeric) != .orderedAscending
    }
    
    // MARK: - Swizzle Disabled methods
    @objc public func applicationDidFinishLaunching(launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        LeanplumUtils.lpLog(type: .debug, format: "Called applicationDidFinishLaunching: %@, state %d", launchOptions ?? [:], UIApplication.shared.applicationState.rawValue)
        if let launchOptions = launchOptions {
            self.leanplum_applicationDidFinishLaunching(launchOptions: launchOptions)
        }
    }
    
    @objc public func didReceiveRemoteNotification(userInfo: [AnyHashable : Any], fetchCompletionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        self.leanplum_application(UIApplication.shared, didReceiveRemoteNotification: userInfo, fetchCompletionHandler: fetchCompletionHandler)
    }
    
    @available(iOS 10.0, *)
    @objc public func userNotificationCenter(didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        self.leanplum_userNotificationCenter(UNUserNotificationCenter.current(), didReceive: response, withCompletionHandler: completionHandler)
    }
    
    @available(iOS 10.0, *)
    @objc public func userNotificationCenter(willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        self.leanplum_userNotificationCenter(UNUserNotificationCenter.current(), willPresent: notification, withCompletionHandler: completionHandler)
    }
    
    @objc public func application(didReceive notification: UILocalNotification) {
        self.leanplum_application(UIApplication.shared, didReceive: notification)
    }
    
    @objc public func handleActionWithIdentifier(_ identifier:String, forRemoteNotification notification: [AnyHashable:Any]) {
        self.notificationOpened(userInfo: notification, action: identifier)
    }
    
    @objc public func handleActionWithIdentifier(_ identifier:String, forLocalNotification notification: UILocalNotification) {
        if let userInfo = notification.userInfo {
            self.notificationOpened(userInfo: userInfo, action: identifier)
        }
    }
    
    // MARK: - swizzleTokenMethods
    func swizzleTokenMethods() {
        // didRegister
        let applicationDidRegisterForRemoteNotificationsWithDeviceToken = #selector(UIApplicationDelegate.application(_:didRegisterForRemoteNotificationsWithDeviceToken:))
        
        let leanplum_applicationDidRegisterForRemoteNotificationsWithDeviceToken = #selector(leanplum_application(_:didRegisterForRemoteNotificationsWithDeviceToken:))
        
        self.swizzledApplicationDidRegisterRemoteNotifications =
        LPSwizzle.hook(into: applicationDidRegisterForRemoteNotificationsWithDeviceToken, with: leanplum_applicationDidRegisterForRemoteNotificationsWithDeviceToken, for: appDelegateClass)
        
        // didFailToRegister
        let applicationDidFailToRegisterForRemoteNotificationsWithError = #selector(UIApplicationDelegate.application(_:didFailToRegisterForRemoteNotificationsWithError:))
        
        let leanplum_applicationDidFailToRegisterForRemoteNotificationsWithError = #selector(leanplum_application(_:didFailToRegisterForRemoteNotificationsWithError:))
        
        self.swizzledApplicationDidFailToRegisterForRemoteNotificationsWithError =
        LPSwizzle.hook(into: applicationDidFailToRegisterForRemoteNotificationsWithError, with: leanplum_applicationDidFailToRegisterForRemoteNotificationsWithError, for: appDelegateClass)
    }
    
    func hasImplementedApplicationDidReceive() -> Bool {
        let applicationDidReceiveRemoteNotificationSelector =
        #selector(UIApplicationDelegate.application(_:didReceiveRemoteNotification:))
        
        let applicationDidReceiveRemoteNotificationMethod = class_getInstanceMethod(appDelegateClass, applicationDidReceiveRemoteNotificationSelector);
        
        return applicationDidReceiveRemoteNotificationMethod != nil
    }
    
    func swizzleApplicationDidReceiveFetchCompletionHandler(_ force:Bool = false) {
        let applicationDidReceiveRemoteNotificationFetchCompletionHandlerSelector =
        #selector(UIApplicationDelegate.application(_:didReceiveRemoteNotification:fetchCompletionHandler:))
        
        let applicationDidReceiveRemoteNotificationCompletionHandlerMethod = class_getInstanceMethod(appDelegateClass, applicationDidReceiveRemoteNotificationFetchCompletionHandlerSelector);
        
        let leanplum_applicationDidReceiveRemoteNotificationFetchCompletionHandlerSelector =
        #selector(leanplum_application(_:didReceiveRemoteNotification:fetchCompletionHandler:))
        
        let swizzleApplicationDidReceiveRemoteNotificationFetchCompletionHandler = { [weak self] in
            self?.swizzledApplicationDidReceiveRemoteNotificationWithCompletionHandler =
            LPSwizzle.hook(into: applicationDidReceiveRemoteNotificationFetchCompletionHandlerSelector, with: leanplum_applicationDidReceiveRemoteNotificationFetchCompletionHandlerSelector, for: self?.appDelegateClass)
        }
        
        if applicationDidReceiveRemoteNotificationCompletionHandlerMethod != nil || force {
            swizzleApplicationDidReceiveRemoteNotificationFetchCompletionHandler()
        }
    }
    
    @available(iOS 10.0, *)
    func swizzleUNUserNotificationCenterMethods() {
        // userNotificationCenter:didReceive:withCompletionHandler:
        let userNotificationCenterDidReceiveNotificationResponseWithCompletionHandlerSelector = #selector(UNUserNotificationCenterDelegate.userNotificationCenter(_:didReceive:withCompletionHandler:))
        
        let userNotificationCenterDidReceiveNotificationResponseWithCompletionHandlerMethod =
        class_getInstanceMethod(appDelegateClass,
                                userNotificationCenterDidReceiveNotificationResponseWithCompletionHandlerSelector)
        
        let leanplum_userNotificationCenterDidReceiveNotificationResponseWithCompletionHandlerSelector = #selector(leanplum_userNotificationCenter(_:didReceive:withCompletionHandler:))
        
        let swizzleUserNotificationDidReceiveNotificationResponseWithCompletionHandler = { [weak self] in
            self?.swizzledUserNotificationCenterDidReceiveNotificationResponseWithCompletionHandler =
            LPSwizzle.hook(into: userNotificationCenterDidReceiveNotificationResponseWithCompletionHandlerSelector, with: leanplum_userNotificationCenterDidReceiveNotificationResponseWithCompletionHandlerSelector, for: self?.userNotificationCenterDelegateClass)
        }
        
        // userNotificationCenter:willPresent:withCompletionHandler:
        let userNotificationCenterWillPresentNotificationWithCompletionHandlerSelector = #selector(UNUserNotificationCenterDelegate.userNotificationCenter(_:willPresent:withCompletionHandler:))
        
        let leanplum_userNotificationCenterWillPresentNotificationWithCompletionHandlerSelector = #selector(self.leanplum_userNotificationCenter(_:willPresent:withCompletionHandler:))
        
        let swizzleUserNotificationWillPresentNotificationWithCompletionHandler = { [weak self] in
            self?.swizzledUserNotificationCenterWillPresentNotificationWithCompletionHandler =
            LPSwizzle.hook(into: userNotificationCenterWillPresentNotificationWithCompletionHandlerSelector, with: leanplum_userNotificationCenterWillPresentNotificationWithCompletionHandlerSelector, for: self?.userNotificationCenterDelegateClass)
        }
        
        if UNUserNotificationCenter.current().delegate != nil {
            // Fallback on didReceive only,
            // application:didReceiveRemoteNotification:fetchCompletionHandler: is called after
            // userNotificationCenter:willPresent:withCompletionHandler: by iOS
            if userNotificationCenterDidReceiveNotificationResponseWithCompletionHandlerMethod != nil {
                hasImplementedNotifCenterMethods = true
            }
            
            userNotificationCenterDelegateClass = object_getClass(UNUserNotificationCenter.current().delegate)
            
            swizzleUserNotificationDidReceiveNotificationResponseWithCompletionHandler()
            swizzleUserNotificationWillPresentNotificationWithCompletionHandler()
        } else {
            LeanplumUtils.lpLog(type: .info, format: "\(userNotificationDelegateName) is not set.")
            let userNotificationCenterDelegateProtocol = objc_getProtocol(userNotificationDelegateName)
            if let notifProtocol = userNotificationCenterDelegateProtocol, let applicationDelegate = appDelegate {
                var conforms = applicationDelegate.conforms(to: notifProtocol)
                if !conforms {
                    // Check explicitly if it fails to add it, not only if the protocol is already there
                    conforms = class_addProtocol(appDelegateClass, notifProtocol)
                }
                
                if conforms, let notifDelegate = applicationDelegate as? UNUserNotificationCenterDelegate {
                    LeanplumUtils.lpLog(type: .info, format: "Setting \(userNotificationDelegateName).")
                    UNUserNotificationCenter.current().delegate = notifDelegate
                    swizzleUserNotificationDidReceiveNotificationResponseWithCompletionHandler()
                    swizzleUserNotificationWillPresentNotificationWithCompletionHandler()
                } else {
                    LeanplumUtils.lpLog(type: .error, format: "Failed to set \(userNotificationDelegateName).")
                }
            }
        }
    }
    
    func swizzleLocalNotificationMethods() {
        // Detect local notifications while app is running
        let applicationDidReceiveLocalNotification = #selector(UIApplicationDelegate.application(_:didReceive:))
        let leanplum_applicationDidReceiveLocalNotification = #selector(leanplum_application(_:didReceive:))
        self.swizzledApplicationDidReceiveLocalNotification =
        LPSwizzle.hook(into: applicationDidReceiveLocalNotification, with: leanplum_applicationDidReceiveLocalNotification, for: appDelegateClass)
    }
    
    func swizzleUserNotificationSettings() {
        let applicationDidRegisterUserNotificationSettings = #selector(UIApplicationDelegate.application(_:didRegister:))
        let leanplum_applicationDidRegisterUserNotificationSettings = #selector(leanplum_application(_:didRegister:))
        
        self.swizzledApplicationDidRegisterUserNotificationSettings =
        LPSwizzle.hook(into: applicationDidRegisterUserNotificationSettings, with: leanplum_applicationDidRegisterUserNotificationSettings, for: appDelegateClass)
    }
    
    @objc public func swizzleNotificationMethods() {
        if !LPUtils.isSwizzlingEnabled() {
            LeanplumUtils.lpLog(type: .info, format: "Method swizzling is disabled, make sure to manually call Leanplum methods.")
            return
        }
        
        LeanplumUtils.lpLog(type: .info, format: "Method swizzling started.")
        
        swizzleTokenMethods()
        
        // Try to swizzle UNUserNotificationCenterDelegate methods
        //        if #available(iOS 10.0, *) {
        if isIOSVersionGreaterThanOrEqual("10"), #available(iOS 10.0, *) {
            // TODO: listen for setting of the delegate or require it to be before leanplum starts
            swizzleUNUserNotificationCenterMethods()
            swizzleApplicationDidReceiveFetchCompletionHandler()
            if !swizzledApplicationDidReceiveRemoteNotificationWithCompletionHandler {
                // if background modes / content-available:1, swizzle for prefetch
                swizzleApplicationDidReceiveFetchCompletionHandler(true)
            } else if !hasImplementedNotifCenterMethods {
                // application:didReceiveRemoteNotification:fetchCompletionHandler: method is implemented and
                // notificationCenter methods are not, we need to call that method manually,
                // since we set our own notification center delegate
                shouldFallbackToLegacyMethods = true
            }
        } else {
            swizzleUserNotificationSettings()
            swizzleLocalNotificationMethods()
            
            swizzleApplicationDidReceiveFetchCompletionHandler()
            if !swizzledApplicationDidReceiveRemoteNotificationWithCompletionHandler {
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
