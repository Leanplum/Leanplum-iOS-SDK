//
//  LeanplumPushNotificationsProxy.swift
//  Leanplum-iOS-SDK
//
//  Created by Nikola Zagorchev on 29.09.21.
//  Copyright © 2021 Leanplum. All rights reserved.

import Foundation
import UIKit

public class LeanplumPushNotificationsProxy: NSObject {
    // MARK: - Initialization
    internal override init() {}
    
    // TimeInterval when application was resumed
    // Used for iOS 9 notifications when state changes from inactive to active
    @objc public var resumedTimeInterval:Double = 0
    
    lazy var appDelegate = UIApplication.shared.delegate
    lazy var appDelegateClass: AnyClass? = object_getClass(appDelegate)
    lazy var userNotificationCenterDelegateClass: AnyClass? = appDelegateClass
    
    var pushNotificationBackgroundFetchResult:UIBackgroundFetchResult = .newData
    var isCustomAppDelegateUsed = false
    
    @objc @available(iOS 10.0, *) 
    public lazy var pushNotificationPresentationOption:UNNotificationPresentationOptions = [] // UNNotificationPresentationOptionNone
    
    let userNotificationDelegateName = "UNUserNotificationCenterDelegate"
    
    private(set) var swizzledApplicationDidRegisterRemoteNotifications = false
    private(set) var swizzledApplicationDidFailToRegisterForRemoteNotificationsWithError = false
    
    private(set) var swizzledApplicationDidReceiveRemoteNotificationWithCompletionHandler = false
    
    private(set) var swizzledUserNotificationCenterDidReceiveNotificationResponseWithCompletionHandler = false
    private(set) var swizzledUserNotificationCenterWillPresentNotificationWithCompletionHandler = false
    
    private(set) var swizzledApplicationDidReceiveLocalNotification = false
    
    private(set) var swizzledApplicationDidRegisterUserNotificationSettings = false
    
    private(set) var hasImplementedNotifCenterMethods = false
    private(set) var shouldFallbackToLegacyMethods = false
    
    private(set) var notificationOpenedFromStart = false
    private(set) var notificationHandledFromStart:[AnyHashable:Any]?
    
    // MARK: - Application didFinishLaunching
    @objc public func addDidFinishLaunchingObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(leanplum_applicationDidFinishLaunching(notification:)), name: UIApplication.didFinishLaunchingNotification, object: nil)
    }
    
    @objc public func removeDidFinishLaunchingObserver() {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func leanplum_applicationDidFinishLaunching(notification: Notification) {
        Log.debug("Called leanplum_applicationDidFinishLaunching: \(notification.userInfo ?? [:]), state \(UIApplication.shared.applicationState.rawValue))")
        
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
                Leanplum.notificationsManager().notificationReceived(userInfo: remoteNotif, isForeground: false)
            } else {
                notificationOpenedFromStart = true
                Leanplum.notificationsManager().notificationOpened(userInfo: remoteNotif)
            }
        } else if let localNotif = launchOptions[UIApplication.LaunchOptionsKey.localNotification] as? UILocalNotification,
                  let userInfo = localNotif.userInfo {
            notificationHandledFromStart = userInfo
            notificationOpenedFromStart = true
            Leanplum.notificationsManager().notificationOpened(userInfo: userInfo)
        }
    }
    
    // MARK: - Methods Swizzling Disabled
    @objc public func applicationDidFinishLaunching(launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
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
        Leanplum.notificationsManager().notificationOpened(userInfo: notification, action: identifier)
    }
    
    @objc public func handleActionWithIdentifier(_ identifier:String, forLocalNotification notification: UILocalNotification) {
        if let userInfo = notification.userInfo {
            Leanplum.notificationsManager().notificationOpened(userInfo: userInfo, action: identifier)
        }
    }
    
    // MARK: - Swizzle Push Token Methods
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
    
    // MARK: - Swizzle Application didReceiveRemoteNotification
    
    /**
     * Check if didReceiveRemoteNotification is implemented (deprecated in iOS 10).
     * If :didReceiveRemoteNotification:fetchCompletionHandler: is implemented the above mentioned method
     * will not be called
     */
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
    
    // MARK: - Swizzle UNUserNotificationCenter methods
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
            Log.debug("\(userNotificationDelegateName) is not set.")
            let userNotificationCenterDelegateProtocol = objc_getProtocol(userNotificationDelegateName)
            if let notifProtocol = userNotificationCenterDelegateProtocol, let applicationDelegate = appDelegate {
                var conforms = applicationDelegate.conforms(to: notifProtocol)
                if !conforms {
                    // Check explicitly if it fails to add it, not only if the protocol is already there
                    conforms = class_addProtocol(appDelegateClass, notifProtocol)
                }
                
                if conforms, let notifDelegate = applicationDelegate as? UNUserNotificationCenterDelegate {
                    Log.debug("Setting \(userNotificationDelegateName).")
                    UNUserNotificationCenter.current().delegate = notifDelegate
                    swizzleUserNotificationDidReceiveNotificationResponseWithCompletionHandler()
                    swizzleUserNotificationWillPresentNotificationWithCompletionHandler()
                } else {
                    Log.debug("Failed to set \(userNotificationDelegateName).")
                }
            }
        }
    }
    
    // MARK: - Swizzle Local Notification method
    func swizzleLocalNotificationMethods() {
        // Detect local notifications while app is running
        let applicationDidReceiveLocalNotification = #selector(UIApplicationDelegate.application(_:didReceive:))
        let leanplum_applicationDidReceiveLocalNotification = #selector(leanplum_application(_:didReceive:))
        self.swizzledApplicationDidReceiveLocalNotification =
        LPSwizzle.hook(into: applicationDidReceiveLocalNotification, with: leanplum_applicationDidReceiveLocalNotification, for: appDelegateClass)
    }
    
    // MARK: - Swizzle Notification Settings method
    func swizzleUserNotificationSettings() {
        let applicationDidRegisterUserNotificationSettings = #selector(UIApplicationDelegate.application(_:didRegister:))
        let leanplum_applicationDidRegisterUserNotificationSettings = #selector(leanplum_application(_:didRegister:))
        
        self.swizzledApplicationDidRegisterUserNotificationSettings =
        LPSwizzle.hook(into: applicationDidRegisterUserNotificationSettings, with: leanplum_applicationDidRegisterUserNotificationSettings, for: appDelegateClass)
    }
    
    // MARK: - Swizzle All Methods
    @objc public func swizzleNotificationMethods() {
        if !LPUtils.isSwizzlingEnabled() {
            Log.info("Method swizzling is disabled, make sure to manually call Leanplum methods.")
            return
        }
        
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
    
    // MARK: - Utils
    func isEqualToHandledNotification(userInfo: [AnyHashable : Any]) -> Bool {
        if let fromStart = notificationHandledFromStart {
            let idA = Leanplum.notificationsManager().getNotificationId(fromStart)
            let idB = Leanplum.notificationsManager().getNotificationId(userInfo)
            return idA == idB
        }
        
        return false
    }
    
    @objc public func setCustomAppDelegate(_ appDel: UIApplicationDelegate) {
        isCustomAppDelegateUsed = true
        appDelegate = appDel
    }
    
    /**
     * Ensures the original AppDelegate is swizzled when using mParticle
     * or another library that proxies the AppDelegate that way
     */
    func ensureOriginalAppDelegate() {
        if let appDel = appDelegate, String(describing: appDel.self).contains("AppDelegateProxy") {
            let sel = Selector(("originalAppDelegate"))
            let method = class_getInstanceMethod(object_getClass(appDel), sel)
            if let m = method {
                let imp = method_getImplementation(m)
                typealias OriginalAppDelegateGetter = @convention(c) (AnyObject, Selector) -> UIApplicationDelegate?
                let curriedImplementation:OriginalAppDelegateGetter = unsafeBitCast(imp, to: OriginalAppDelegateGetter.self)
                let originalAppDelegate = curriedImplementation(appDel, sel)
                if originalAppDelegate != nil {
                    appDelegate = originalAppDelegate
                }
            }
        }
    }
}
