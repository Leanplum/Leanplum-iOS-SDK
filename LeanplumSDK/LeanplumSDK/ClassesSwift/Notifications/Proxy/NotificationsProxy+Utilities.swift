//
//  NotificationsProxy+Utilities.swift
//  LeanplumSDK
//
//  Created by Nikola Zagorchev on 23.12.21.
//  Copyright © 2023 Leanplum. All rights reserved.

import Foundation

extension NotificationsProxy {
    
    func isEqualToHandledNotification(userInfo: [AnyHashable: Any]) -> Bool {
        if let fromStart = notificationHandledFromStart {
            let idA = Leanplum.notificationsManager().getNotificationId(fromStart)
            let idB = Leanplum.notificationsManager().getNotificationId(userInfo)
            // CleverTap notifications do not have notification Id
            return idA == idB && idA != "-1"
        }
        return false
    }
    
    @objc public func setCustomAppDelegate(_ delegate: UIApplicationDelegate) {
        isCustomAppDelegateUsed = true
        appDelegate = delegate
    }
    
    /// Ensures the original AppDelegate is swizzled when using mParticle
    /// or another library that proxies the AppDelegate that way
    func ensureOriginalAppDelegate() {
        if let delegate = appDelegate, String(describing: delegate.self).contains("AppDelegateProxy") {
            let sel = Selector(("originalAppDelegate"))
            let method = class_getInstanceMethod(object_getClass(delegate), sel)
            if let instanceMethod = method {
                let imp = method_getImplementation(instanceMethod)
                typealias OriginalAppDelegateGetter = @convention(c) (AnyObject, Selector) -> UIApplicationDelegate?
                let curriedImplementation: OriginalAppDelegateGetter =
                unsafeBitCast(imp, to: OriginalAppDelegateGetter.self)
                let originalAppDelegate = curriedImplementation(delegate, sel)
                if originalAppDelegate != nil {
                    appDelegate = originalAppDelegate
                }
            }
        }
    }
}
