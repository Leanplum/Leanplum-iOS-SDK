//
//  NotificationsProxy+iOS9.swift
//  LeanplumSDK
//
//  Created by Nikola Zagorchev on 23.12.21.
//  Copyright © 2021 Leanplum. All rights reserved.

import Foundation

extension NotificationsProxy {
    /// Check if didReceiveRemoteNotification is implemented (deprecated in iOS 10).
    /// If :didReceiveRemoteNotification:fetchCompletionHandler: is implemented the above mentioned method
    /// will not be called
    func hasImplementedApplicationDidReceive() -> Bool {
        let applicationDidReceiveRemoteNotificationSelector = #selector(UIApplicationDelegate.application(_:didReceiveRemoteNotification:))
        let applicationDidReceiveRemoteNotificationMethod = class_getInstanceMethod(appDelegateClass,
                                                                                    applicationDidReceiveRemoteNotificationSelector)
        return applicationDidReceiveRemoteNotificationMethod != nil
    }
    
    /// Swizzle Local Notification method
    func swizzleLocalNotificationMethods() {
        // Detect local notifications while app is running
        let applicationDidReceiveLocalNotification = #selector(UIApplicationDelegate.application(_:didReceive:))
        let leanplum_applicationDidReceiveLocalNotification = #selector(leanplum_application(_:didReceive:))
        swizzled.applicationDidReceiveLocalNotification = LPSwizzle.hook(into: applicationDidReceiveLocalNotification,
                                                                         with: leanplum_applicationDidReceiveLocalNotification,
                                                                         for: appDelegateClass)
    }
    
    /// Swizzle Notification Settings method
    func swizzleUserNotificationSettings() {
        let applicationDidRegisterUserNotificationSettings = #selector(UIApplicationDelegate.application(_:didRegister:))
        let leanplum_applicationDidRegisterUserNotificationSettings = #selector(leanplum_application(_:didRegister:))
        swizzled.applicationDidRegisterUserNotificationSettings = LPSwizzle.hook(into: applicationDidRegisterUserNotificationSettings,
                                                                                 with: leanplum_applicationDidRegisterUserNotificationSettings,
                                                                                 for: appDelegateClass)
    }
}
