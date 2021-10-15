//
//  LeanplumPushNotificationsProxy.swift
//  Leanplum-iOS-SDK
//
//  Created by Nikola Zagorchev on 29.09.21.
//

import Foundation
import UIKit

public class LeanplumPushNotificationsProxy: NSObject {
    
    @objc public static let shared = LeanplumPushNotificationsProxy()
    
    private override init() {}
    
    @objc public var deviceVersion:String?
    
    lazy var appDelegate = UIApplication.shared.delegate
    lazy var appDelegateClass: AnyClass? = object_getClass(appDelegate)
    lazy var userNotificationCenterDelegateClass: AnyClass? = appDelegateClass
    
    var pushNotificationBackgroundFetchResult:UIBackgroundFetchResult = .newData
    
    @available(iOS 10.0, *)
    lazy var pushNotificationPresentationOption:UNNotificationPresentationOptions = [] // UNNotificationPresentationOptionNone
    
    private(set) var swizzledApplicationDidRegisterRemoteNotifications = false
    private(set) var swizzledApplicationDidFailToRegisterForRemoteNotificationsWithError = false
    
    //    private(set) var swizzledApplicationDidReceiveRemoteNotification = false
    private(set) var swizzledApplicationDidReceiveRemoteNotificationWithCompletionHandler = false
    
    private(set) var swizzledUserNotificationCenterDidReceiveNotificationResponseWithCompletionHandler = false
    private(set) var swizzledUserNotificationCenterWillPresentNotificationWithCompletionHandler = false
    
    private(set) var swizzledApplicationDidReceiveLocalNotification = false
    
    private(set) var swizzledApplicationDidRegisterUserNotificationSettings = false
    
    private(set) var notificationOpenedFromStart = false
    private(set) var notificationHandledFromStart:[AnyHashable:Any]?
    
    private(set) var hasImplementedNotifCenterMethods = false
    private(set) var shouldFallbackToLegacyMethods = false
    
    @objc static public func addDidFinishLaunchingObserver() {
        NotificationCenter.default.addObserver(self.shared, selector: #selector(leanplum_applicationDidFinishLaunching(notification:)), name: UIApplication.didFinishLaunchingNotification, object: nil)
    }
    
    @objc static public func removeDidFinishLaunchingObserver() {
        NotificationCenter.default.removeObserver(self.shared)
    }
    
    @objc func leanplum_applicationDidFinishLaunching(notification: Notification) {
        self.swizzleNotificationMethods()
        if let remoteNotif = notification.userInfo?[UIApplication.LaunchOptionsKey.remoteNotification] as? [AnyHashable : Any] {
            self.notificationHandledFromStart = remoteNotif
            
            LeanplumUtils.lpLog(type: .debug, format: "leanplum_applicationDidFinishLaunching: %@, state %d", LeanplumUtils.getNotificationId(remoteNotif), UIApplication.shared.applicationState.rawValue)
            
            // started in background, woken up by remote notification
            if UIApplication.shared.applicationState == .background {
                notificationOpenedFromStart = false
                notificationReceived(userInfo: remoteNotif, isForeground: false)
            } else {
                notificationOpenedFromStart = true
                notificationOpened(userInfo: remoteNotif)
            }
            // TODO: check for local
        }
    }
    
    func notificationOpened(userInfo: [AnyHashable : Any], action: String = LP_VALUE_DEFAULT_PUSH_ACTION) {
        LeanplumUtils.lpLog(type: .debug, format: "notificationOpened: %@", LeanplumUtils.getNotificationId(userInfo))
        
        let messageId = LeanplumUtils.getNotificationId(userInfo)
        let actionName = action == LP_VALUE_DEFAULT_PUSH_ACTION ? action : "iOS options.Custom actions.\(action)"
        
        let actionsEmbedded = userInfo[LP_KEY_PUSH_ACTION] != nil ||
        userInfo[LP_KEY_PUSH_CUSTOM_ACTIONS] != nil
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
        if isForeground {
            // TODO: check if should be muted
            LeanplumUtils.lpLog(type: .debug, format: "notificationReceived Foreground: %@", LeanplumUtils.getNotificationId(userInfo))
            
            if !LeanplumUtils.isMuted(userInfo) {
                showNotificationInForeground(userInfo: userInfo)
            }
        } else {
            LeanplumUtils.lpLog(type: .debug, format: "notificationReceived Background: %@", LeanplumUtils.getNotificationId(userInfo))
            
            if !LeanplumUtils.areActionsEmbedded(userInfo) {
                
            }
        }
        
        // TODO: check if notification action is not embedded and needs FCU / Prefetch
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
            
            LeanplumUtils.lpLog(type: .debug, format: "isEqual: %@, %@", idA, idB)
            return idA == idB
        }
        
        return false
    }
    
    func isIOSVersionGreaterThanOrEqual(_ version:String) -> Bool {
        let currentVersion = UIDevice.current.systemVersion
        return (deviceVersion ?? currentVersion).compare(version,options: .numeric) != .orderedAscending
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
    
    //    @objc public func swizzleApplicationDidReceive(_ force:Bool = false) -> Bool {
    //        let applicationDidReceiveRemoteNotificationSelector =
    //        #selector(UIApplicationDelegate.application(_:didReceiveRemoteNotification:))
    //
    //        let applicationDidReceiveRemoteNotificationMethod = class_getInstanceMethod(appDelegateClass, applicationDidReceiveRemoteNotificationSelector);
    //
    //        let leanplum_applicationDidReceiveRemoteNotificationSelector =
    //        #selector(leanplum_application(_:didReceiveRemoteNotification:))
    //
    //        let swizzleApplicationDidReceiveRemoteNotification = { [weak self] in
    //            self?.swizzledApplicationDidReceiveRemoteNotification =
    //            LPSwizzle.hook(into: applicationDidReceiveRemoteNotificationSelector, with: leanplum_applicationDidReceiveRemoteNotificationSelector, for: self?.appDelegateClass)
    //        }
    //
    //        // Swizzle the method if implemented or add it if forced
    //        if applicationDidReceiveRemoteNotificationMethod != nil || force {
    //            swizzleApplicationDidReceiveRemoteNotification()
    //            return swizzledApplicationDidReceiveRemoteNotification
    //        }
    //        return false
    //    }
    
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
        
        let userNotificationCenterWillPresentNotificationWithCompletionHandlerMethod = class_getInstanceMethod(userNotificationCenterDelegateClass, userNotificationCenterWillPresentNotificationWithCompletionHandlerSelector)
        
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
            
            swizzleUserNotificationDidReceiveNotificationResponseWithCompletionHandler()
            swizzleUserNotificationWillPresentNotificationWithCompletionHandler()
        } else {
            LeanplumUtils.lpLog(type: .info, format: "UNUserNotificationCenterDelegate is not set.")
            let userNotificationCenterDelegateProtocol = objc_getProtocol("UNUserNotificationCenterDelegate")
            if let notifProtocol = userNotificationCenterDelegateProtocol, let notifCenterDelegate = appDelegate {
                let conformsToProtocol = {
                    return notifCenterDelegate.conforms(to: notifProtocol)
                }
                
                if !conformsToProtocol() {
                    class_addProtocol(appDelegateClass, notifProtocol)
                }
                
                if conformsToProtocol(), let notifDelegate = notifCenterDelegate as? UNUserNotificationCenterDelegate {
                    LeanplumUtils.lpLog(type: .info, format: "Setting UNUserNotificationCenterDelegate.")
                    UNUserNotificationCenter.current().delegate = notifDelegate
                    swizzleUserNotificationDidReceiveNotificationResponseWithCompletionHandler()
                    swizzleUserNotificationWillPresentNotificationWithCompletionHandler()
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
