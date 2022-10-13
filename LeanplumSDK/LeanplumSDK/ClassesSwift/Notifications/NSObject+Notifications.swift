//
//  NSObject+Notifications.swift
//  Leanplum-iOS-SDK
//
//  Created by Nikola Zagorchev on 30.09.21.
//  Copyright © 2022 Leanplum. All rights reserved.

import Foundation
import UIKit

/// LP Swizzling looks for the selector in the same class
extension NSObject {

    private var notificationsProxy: NotificationsProxy {
        return Leanplum.notificationsManager().proxy
    }
    
    private var swizzling: NotificationsProxy.Swizzled {
        return notificationsProxy.swizzled
    }
    
    // MARK: - Register For Remote Notifications
    @objc func leanplum_application(_ application: UIApplication,
                                    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Leanplum.notificationsManager().didRegisterForRemoteNotificationsWithDeviceToken(deviceToken)
        
        // Call overridden method
        let selector = #selector(self.leanplum_application(_:didRegisterForRemoteNotificationsWithDeviceToken:))
        if swizzling.applicationDidRegisterRemoteNotifications && self.responds(to: selector) {
            self.perform(selector, with: application, with: deviceToken)
        }
    }
    
    @objc func leanplum_application(_ application: UIApplication,
                                    didFailToRegisterForRemoteNotificationsWithError error: Error) {
        Leanplum.notificationsManager().didFailToRegisterForRemoteNotificationsWithError(error)
        
        // Call overridden method
        let selector = #selector(self.leanplum_application(_:didFailToRegisterForRemoteNotificationsWithError:))
        if swizzling.applicationDidRegisterRemoteNotifications && self.responds(to: selector) {
            self.perform(selector, with: application, with: error)
        }
    }
    
    // MARK: - didReceiveRemoteNotification
    @objc func leanplum_application(_ application: UIApplication,
                                     didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        Log.debug("Called swizzled application:didReceiveRemoteNotification:fetchCompletionHandler AppState: \(UIApplication.shared.applicationState.rawValue)")
        
        defer {
            // Call overridden method
            if LPUtils.isSwizzlingEnabled() {
                typealias FetchResultCompletion = ((UIBackgroundFetchResult) -> Void)
                var leanplumCompletionHandler:FetchResultCompletion?
                let selector = #selector(self.leanplum_application(_:didReceiveRemoteNotification:fetchCompletionHandler:))
                
                if swizzling.applicationDidReceiveRemoteNotificationWithCompletionHandler && self.responds(to: selector) {
                    // Prevent calling the completionHandler twice
                    leanplumCompletionHandler = nil
                    // Call method directly since the it requires 3 objects and performSelector supports only 2
                    // otherwise use Method IMP
                    self.leanplum_application(application, didReceiveRemoteNotification: userInfo, fetchCompletionHandler: completionHandler)
                } else {
                    leanplumCompletionHandler = completionHandler
                    
                    if notificationsProxy.shouldFallbackToLegacyMethods {
                        notificationsProxy.appDelegate?.application?(UIApplication.shared, didReceiveRemoteNotification: userInfo)
                    }
                }
                
                // Call completion handler
                leanplumCompletionHandler?(notificationsProxy.pushNotificationBackgroundFetchResult)
            }
        }
        
        let state = UIApplication.shared.applicationState
        // Call notification received or perform action
        if #available(iOS 10, *) {
            // Open notification will be handled by userNotificationCenter:didReceive or
            // application:didFinishLaunchingWithOptions
            // Receiving of notification when app is running on foreground is handled by userNotificationCenter:willPresent
            if !notificationsProxy.isEqualToHandledNotification(userInfo: userInfo) {
                if state == .background {
                    Leanplum.notificationsManager().notificationReceived(userInfo: userInfo, isForeground: false)
                }
            }
        } else {
            leanplum_application_ios9(application, didReceiveRemoteNotification: userInfo, fetchCompletionHandler: completionHandler)
        }
    }
    
    // MARK: iOS 9 didReceiveRemoteNotification
    func leanplum_application_ios9(_ application: UIApplication,
                                     didReceiveRemoteNotification userInfo: [AnyHashable : Any],
                                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // iOS 9
        let state = UIApplication.shared.applicationState
        // Notification was not handled by application:didFinishLaunchingWithOptions
        if !notificationsProxy.isEqualToHandledNotification(userInfo: userInfo) {
        if  state == .inactive {
            // Open
            Leanplum.notificationsManager().notificationOpened(userInfo: userInfo)
        } else if state == .active {
            // There are cases where state has changed to active from inactive, when user tapped the notification
            // If app entered foreground right before calling this method, the app became active because notification was tapped
            // Otherwise, notification was received while app was active/foreground
            if notificationsProxy.resumedTimeInterval + 0.500 > NSDate().timeIntervalSince1970 {
                Leanplum.notificationsManager().notificationOpened(userInfo: userInfo)
            } else {
                Leanplum.notificationsManager().notificationReceived(userInfo: userInfo, isForeground: true)
            }
        } else {
            Leanplum.notificationsManager().notificationReceived(userInfo: userInfo, isForeground: false)
        }
        // App was waken up by notification, its receiving was handled by application:didFinishLaunchingWithOptions
        // didReceiveRemoteNotification is called again when user tapped it
        } else if !notificationsProxy.notificationOpenedFromStart && state != .background {
            Leanplum.notificationsManager().notificationOpened(userInfo: userInfo)
        }
    }
    
    // MARK: - UserNotificationCenter
    @objc @available(iOS 10.0, *)
    func leanplum_userNotificationCenter(_ center: UNUserNotificationCenter,
                                         didReceive response: UNNotificationResponse,
                                         withCompletionHandler completionHandler: @escaping () -> Void) {
        Log.debug("Called swizzled userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler")
        
        let userInfo = response.notification.request.content.userInfo
        defer {
            // Call overridden method
            if LPUtils.isSwizzlingEnabled() {
                let selector = #selector(self.leanplum_userNotificationCenter(_:didReceive:withCompletionHandler:))
                if swizzling.userNotificationCenterDidReceiveNotificationResponseWithCompletionHandler && self.responds(to: selector) {
                    // Call original method
                    self.leanplum_userNotificationCenter(center, didReceive: response, withCompletionHandler: completionHandler)
                } else {
                    if notificationsProxy.shouldFallbackToLegacyMethods {
                        // Call iOS 10 UNUserNotificationCenter completionHandler from iOS 9's fetchCompletion handler
                        self.leanplum_application(UIApplication.shared, didReceiveRemoteNotification: userInfo, fetchCompletionHandler: { res in
                            completionHandler()
                        })
                    } else {
                        // Client has not implemented anything, call the completionHandler
                        completionHandler()
                    }
                }
            }
        }
        
        // Handle UNNotificationDefaultActionIdentifier and Custom Actions
        if response.actionIdentifier != UNNotificationDismissActionIdentifier {
            let notifWasOpenedFromStart = notificationsProxy.isEqualToHandledNotification(userInfo: userInfo) && notificationsProxy.notificationOpenedFromStart
            if !notifWasOpenedFromStart {
                // Open Notification action
                if response.actionIdentifier == UNNotificationDefaultActionIdentifier {
                    Leanplum.notificationsManager().notificationOpened(userInfo: userInfo)
                } else {
                    // Open Custom Action
                    Leanplum.notificationsManager().notificationOpened(userInfo: userInfo, action: response.actionIdentifier)
                }
            }
        }
    }
    
    @objc @available(iOS 10.0, *)
    func leanplum_userNotificationCenter(_ center: UNUserNotificationCenter,
                                         willPresent notification: UNNotification,
                                         withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        Log.debug("Called swizzled userNotificationCenter:willPresentNotification:withCompletionHandler")
        
        defer {
            // Call overridden method
            let selector = #selector(self.leanplum_userNotificationCenter(_:willPresent:withCompletionHandler:))
            if swizzling.userNotificationCenterWillPresentNotificationWithCompletionHandler && self.responds(to: selector) {
                self.leanplum_userNotificationCenter(center, willPresent: notification, withCompletionHandler: completionHandler)
            } else {
                completionHandler(notificationsProxy.pushNotificationPresentationOption)
            }
        }
        
        // Notification is received while app is running on foreground
        Leanplum.notificationsManager().notificationReceived(userInfo: notification.request.content.userInfo, isForeground: true)
    }
    
    // MARK: - didReceive Local Notification
    @objc func leanplum_application(_ application: UIApplication, didReceive notification: UILocalNotification) {
        Log.debug("Called swizzled application:didReceive:localNotification")
        
        defer {
            // Call overridden method
            let selector = #selector(self.leanplum_application(_:didReceive:))
            if swizzling.applicationDidReceiveLocalNotification && self.responds(to: selector) {
                self.perform(selector, with: application, with: notification)
            }
        }
        
        guard let userInfo = notification.userInfo else {
            return
        }
        
        if UIApplication.shared.applicationState == .active {
            Leanplum.notificationsManager().notificationReceived(userInfo: userInfo, isForeground: true)
        } else {
            Leanplum.notificationsManager().notificationOpened(userInfo: userInfo)
        }
    }
    
    // MARK: - didRegister Notification Settings
    @objc func leanplum_application(_ application: UIApplication, didRegister notificationSettings: UIUserNotificationSettings) {
        Leanplum.notificationsManager().didRegister(notificationSettings)
        
        // Call overridden method
        let selector = #selector(self.leanplum_application(_:didRegister:))
        if swizzling.applicationDidRegisterUserNotificationSettings && self.responds(to: selector) {
            self.perform(selector, with: application, with: notificationSettings)
        }
    }
}
