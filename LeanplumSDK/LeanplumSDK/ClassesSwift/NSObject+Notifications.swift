//
//  NSObject+Notifications.swift
//  Leanplum-iOS-SDK
//
//  Created by Nikola Zagorchev on 30.09.21.
//  Copyright © 2021 Leanplum. All rights reserved.

import Foundation
import UIKit

// LP Swizzling looks for the selector in the same class
extension NSObject {
    @objc func leanplum_application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Leanplum.notificationsManager().didRegisterForRemoteNotificationsWithDeviceToken(deviceToken)
        
        // Call overridden method
        let selector = #selector(self.leanplum_application(_:didRegisterForRemoteNotificationsWithDeviceToken:))
        if Leanplum.notificationsManager().proxy.swizzledApplicationDidRegisterRemoteNotifications && self.responds(to: selector) {
            self.perform(selector, with: application, with: deviceToken)
        }
    }
    
    @objc func leanplum_application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        Leanplum.notificationsManager().didFailToRegisterForRemoteNotificationsWithError(error)
        
        // Call overridden method
        let selector = #selector(self.leanplum_application(_:didFailToRegisterForRemoteNotificationsWithError:))
        if Leanplum.notificationsManager().proxy.swizzledApplicationDidRegisterRemoteNotifications && self.responds(to: selector) {
            self.perform(selector, with: application, with: error)
        }
    }
    
    @objc func leanplum_application(_ application: UIApplication,
                                     didReceiveRemoteNotification userInfo: [AnyHashable : Any],
                                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        LeanplumUtils.lpLog(type: .debug, format: "Called swizzled didReceiveRemoteNotification:fetchCompletionHandler")
        
        defer {
            // Call overridden method
            if LPUtils.isSwizzlingEnabled() {
                typealias FetchResultCompletion = ((UIBackgroundFetchResult) -> Void)
                var leanplumCompletionHandler:FetchResultCompletion?
                let selector = #selector(self.leanplum_application(_:didReceiveRemoteNotification:fetchCompletionHandler:))
                
                if Leanplum.notificationsManager().proxy.swizzledApplicationDidReceiveRemoteNotificationWithCompletionHandler && self.responds(to: selector) {
                    // Prevent calling the completionHandler twice
                    leanplumCompletionHandler = nil
                    // Call method directly since the it requires 3 objects and performSelector supports only 2
                    // otherwise use Method IMP
                    self.leanplum_application(application, didReceiveRemoteNotification: userInfo, fetchCompletionHandler: completionHandler)
                } else {
                    leanplumCompletionHandler = completionHandler
                    
                    if Leanplum.notificationsManager().proxy.shouldFallbackToLegacyMethods {
                        Leanplum.notificationsManager().proxy.appDelegate?.application?(UIApplication.shared, didReceiveRemoteNotification: userInfo)
                    }
                }
                
                // Call completion handler
                leanplumCompletionHandler?(Leanplum.notificationsManager().proxy.pushNotificationBackgroundFetchResult)
            }
        }
        
        // Do not handle non-Leanplum notifications
        guard LeanplumUtils.messageIdFromUserInfo(userInfo) != nil else {
            return
        }
        
        let state = UIApplication.shared.applicationState
        // Call notification received or perform action
        if Leanplum.notificationsManager().proxy.isIOSVersionGreaterThanOrEqual("10") { //, #available(iOS 10, *) {
            // Open notification will be handled by userNotificationCenter:didReceive or
            // application:didFinishLaunchingWithOptions
            // Receiving of notification when app is running on foreground is handled by userNotificationCenter:willPresent
            if !Leanplum.notificationsManager().proxy.isEqualToHandledNotification(userInfo: userInfo) {
                if state == .background {
                    Leanplum.notificationsManager().notificationReceived(userInfo: userInfo, isForeground: false)
                }
            }
        } else {
            leanplum_application_ios9(application, didReceiveRemoteNotification: userInfo, fetchCompletionHandler: completionHandler)
        }
    }
    
    func leanplum_application_ios9(_ application: UIApplication,
                                     didReceiveRemoteNotification userInfo: [AnyHashable : Any],
                                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // iOS 9
        let state = UIApplication.shared.applicationState
        LeanplumUtils.lpLog(type: .debug, format: "didReceiveRemoteNotification:fetchCompletionHandler: %d", state.rawValue)
        // Notification was not handled by application:didFinishLaunchingWithOptions
        if !Leanplum.notificationsManager().proxy.isEqualToHandledNotification(userInfo: userInfo) {
        if  state == .inactive {
            // Open
            Leanplum.notificationsManager().notificationOpened(userInfo: userInfo)
        } else if state == .active {
            // There are cases where state has changed to active from inactive, when user tapped the notification
            // If app entered foreground right before calling this method, the app became active because notification was tapped
            // Otherwise, notification was received while app was active/foreground
            if Leanplum.notificationsManager().proxy.resumedTimeInterval + 0.500 > NSDate().timeIntervalSince1970 {
                Leanplum.notificationsManager().notificationOpened(userInfo: userInfo)
            } else {
                Leanplum.notificationsManager().notificationReceived(userInfo: userInfo, isForeground: true)
            }
        } else {
            Leanplum.notificationsManager().notificationReceived(userInfo: userInfo, isForeground: false)
        }
        // App was waken up by notification, its receiving was handled by application:didFinishLaunchingWithOptions
        // didReceiveRemoteNotification is called again when user tapped it
        } else if !Leanplum.notificationsManager().proxy.notificationOpenedFromStart && state != .background {
            Leanplum.notificationsManager().notificationOpened(userInfo: userInfo)
        }
    }
    
    @objc @available(iOS 10.0, *)
    func leanplum_userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        LeanplumUtils.lpLog(type: .debug, format: "Called swizzled didReceiveNotificationResponse:withCompletionHandler")
        
        let userInfo = response.notification.request.content.userInfo
        defer {
            // Call overridden method
            if LPUtils.isSwizzlingEnabled() {
                let selector = #selector(self.leanplum_userNotificationCenter(_:didReceive:withCompletionHandler:))
                if Leanplum.notificationsManager().proxy.swizzledUserNotificationCenterDidReceiveNotificationResponseWithCompletionHandler && self.responds(to: selector) {
                    // Call original method
                    self.leanplum_userNotificationCenter(center, didReceive: response, withCompletionHandler: completionHandler)
                } else {
                    if Leanplum.notificationsManager().proxy.shouldFallbackToLegacyMethods {
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
        
        // Do not handle non-Leanplum notifications
        guard LeanplumUtils.messageIdFromUserInfo(userInfo) != nil else {
            return
        }
        
        // Handle UNNotificationDefaultActionIdentifier and Custom Actions
        if response.actionIdentifier != UNNotificationDismissActionIdentifier {
            let notifWasOpenedFromStart = Leanplum.notificationsManager().proxy.isEqualToHandledNotification(userInfo: userInfo) && Leanplum.notificationsManager().proxy.notificationOpenedFromStart
            
            LeanplumUtils.lpLog(type: .debug, format: "notificationOpenedFromStart \(notifWasOpenedFromStart)")
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
    func leanplum_userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        LeanplumUtils.lpLog(type: .debug, format: "Called swizzled willPresentNotification:withCompletionHandler")
        
        defer {
            // Call overridden method
            let selector = #selector(self.leanplum_userNotificationCenter(_:willPresent:withCompletionHandler:))
            if Leanplum.notificationsManager().proxy.swizzledUserNotificationCenterWillPresentNotificationWithCompletionHandler && self.responds(to: selector) {
                self.leanplum_userNotificationCenter(center, willPresent: notification, withCompletionHandler: completionHandler)
            }
        }
        
        // Do not handle non-Leanplum notifications
        guard LeanplumUtils.messageIdFromUserInfo(notification.request.content.userInfo) != nil else {
            return
        }
        
        // Notification is received while app is running on foreground
        Leanplum.notificationsManager().notificationReceived(userInfo: notification.request.content.userInfo, isForeground: true)
    }
    
    @objc func leanplum_application(_ application: UIApplication, didReceive notification: UILocalNotification) {
        LeanplumUtils.lpLog(type: .debug, format: "Called swizzled application:didReceive:localNotification %d", UIApplication.shared.applicationState.rawValue)
        
        defer {
            // Call overridden method
            let selector = #selector(self.leanplum_application(_:didReceive:))
            if Leanplum.notificationsManager().proxy.swizzledApplicationDidReceiveLocalNotification && self.responds(to: selector) {
                self.perform(selector, with: application, with: notification)
            }
        }
        
        // Do not handle non-Leanplum notifications
        guard let userInfo = notification.userInfo, LeanplumUtils.messageIdFromUserInfo(userInfo) != nil else {
            return
        }
        
        if UIApplication.shared.applicationState == .active {
            Leanplum.notificationsManager().notificationReceived(userInfo: userInfo, isForeground: true)
        } else {
            Leanplum.notificationsManager().notificationOpened(userInfo: userInfo)
        }
    }
    
    @objc func leanplum_application(_ application: UIApplication, didRegister notificationSettings: UIUserNotificationSettings) {
        Leanplum.notificationsManager().didRegister(notificationSettings)
        
        // Call overridden method
        let selector = #selector(self.leanplum_application(_:didRegister:))
        if Leanplum.notificationsManager().proxy.swizzledApplicationDidRegisterUserNotificationSettings && self.responds(to: selector) {
            self.perform(selector, with: application, with: notificationSettings)
        }
    }
}
