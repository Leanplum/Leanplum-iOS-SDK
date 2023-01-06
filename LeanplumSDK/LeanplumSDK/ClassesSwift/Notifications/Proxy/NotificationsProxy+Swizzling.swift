//
//  NotificationsProxy+Swizzling.swift
//  LeanplumSDK
//
//  Created by Nikola Zagorchev on 23.12.21.
//  Copyright © 2022 Leanplum. All rights reserved.

import Foundation

extension NotificationsProxy {
 
    struct Swizzled {
        var once = false
        
        var applicationDidRegisterRemoteNotifications = false
        var applicationDidFailToRegisterForRemoteNotificationsWithError = false
        
        var applicationDidReceiveRemoteNotificationWithCompletionHandler = false
        
        var userNotificationCenterDidReceiveNotificationResponseWithCompletionHandler = false
        var userNotificationCenterWillPresentNotificationWithCompletionHandler = false
        
        var applicationDidReceiveLocalNotification = false
        
        var applicationDidRegisterUserNotificationSettings = false
    }
    
    // MARK: - Swizzle Push Token Methods
    func swizzleTokenMethods() {
        // didRegister
        let applicationDidRegisterForRemoteNotificationsWithDeviceToken = #selector(UIApplicationDelegate.application(_:didRegisterForRemoteNotificationsWithDeviceToken:))
        
        let leanplum_applicationDidRegisterForRemoteNotificationsWithDeviceToken = #selector(leanplum_application(_:didRegisterForRemoteNotificationsWithDeviceToken:))
        
        self.swizzled.applicationDidRegisterRemoteNotifications =
        LPSwizzle.hook(into: applicationDidRegisterForRemoteNotificationsWithDeviceToken, with: leanplum_applicationDidRegisterForRemoteNotificationsWithDeviceToken, for: appDelegateClass)
        
        // didFailToRegister
        let applicationDidFailToRegisterForRemoteNotificationsWithError = #selector(UIApplicationDelegate.application(_:didFailToRegisterForRemoteNotificationsWithError:))
        
        let leanplum_applicationDidFailToRegisterForRemoteNotificationsWithError = #selector(leanplum_application(_:didFailToRegisterForRemoteNotificationsWithError:))
        
        swizzled.applicationDidFailToRegisterForRemoteNotificationsWithError =
        LPSwizzle.hook(into: applicationDidFailToRegisterForRemoteNotificationsWithError, with: leanplum_applicationDidFailToRegisterForRemoteNotificationsWithError, for: appDelegateClass)
    }
    
    // MARK: - Swizzle Application didReceiveRemoteNotification
    func swizzleApplicationDidReceiveFetchCompletionHandler(_ force: Bool = false) {
        let applicationDidReceiveRemoteNotificationFetchCompletionHandlerSelector =
        #selector(UIApplicationDelegate.application(_:didReceiveRemoteNotification:fetchCompletionHandler:))
        
        let applicationDidReceiveRemoteNotificationCompletionHandlerMethod = class_getInstanceMethod(appDelegateClass, applicationDidReceiveRemoteNotificationFetchCompletionHandlerSelector);
        
        let leanplum_applicationDidReceiveRemoteNotificationFetchCompletionHandlerSelector =
        #selector(leanplum_application(_:didReceiveRemoteNotification:fetchCompletionHandler:))
        
        let swizzleApplicationDidReceiveRemoteNotificationFetchCompletionHandler = { [weak self] in
            self?.swizzled.applicationDidReceiveRemoteNotificationWithCompletionHandler =
            LPSwizzle.hook(into: applicationDidReceiveRemoteNotificationFetchCompletionHandlerSelector,
                           with: leanplum_applicationDidReceiveRemoteNotificationFetchCompletionHandlerSelector,
                           for: self?.appDelegateClass)
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
            self?.swizzled.userNotificationCenterDidReceiveNotificationResponseWithCompletionHandler =
            LPSwizzle.hook(into: userNotificationCenterDidReceiveNotificationResponseWithCompletionHandlerSelector,
                           with: leanplum_userNotificationCenterDidReceiveNotificationResponseWithCompletionHandlerSelector,
                           for: self?.userNotificationCenterDelegateClass)
        }
        
        // userNotificationCenter:willPresent:withCompletionHandler:
        let userNotificationCenterWillPresentNotificationWithCompletionHandlerSelector = #selector(UNUserNotificationCenterDelegate.userNotificationCenter(_:willPresent:withCompletionHandler:))
        
        let leanplum_userNotificationCenterWillPresentNotificationWithCompletionHandlerSelector = #selector(self.leanplum_userNotificationCenter(_:willPresent:withCompletionHandler:))
        
        let swizzleUserNotificationWillPresentNotificationWithCompletionHandler = { [weak self] in
            self?.swizzled.userNotificationCenterWillPresentNotificationWithCompletionHandler =
            LPSwizzle.hook(into: userNotificationCenterWillPresentNotificationWithCompletionHandlerSelector,
                           with: leanplum_userNotificationCenterWillPresentNotificationWithCompletionHandlerSelector,
                           for: self?.userNotificationCenterDelegateClass)
        }
        
        if UNUserNotificationCenter.current().delegate != nil {
            // Fallback on didReceive only,
            // application:didReceiveRemoteNotification:fetchCompletionHandler: is called after
            // userNotificationCenter:willPresent:withCompletionHandler: by iOS
            if userNotificationCenterDidReceiveNotificationResponseWithCompletionHandlerMethod != nil {
                hasImplementedNotificationCenterMethods = true
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
                    Log.info("Setting \(userNotificationDelegateName).")
                    UNUserNotificationCenter.current().delegate = notifDelegate
                    swizzleUserNotificationDidReceiveNotificationResponseWithCompletionHandler()
                    swizzleUserNotificationWillPresentNotificationWithCompletionHandler()
                } else {
                    Log.error("Failed to set \(userNotificationDelegateName).")
                }
            }
        }
    }
}
