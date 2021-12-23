//
//  NotificationsProxy+Utils.swift
//  LeanplumSDK
//
//  Created by Nikola Zagorchev on 23.12.21.
//  Copyright © 2021 Leanplum. All rights reserved.

import Foundation

extension NotificationsProxy {
    
    func isEqualToHandledNotification(userInfo: [AnyHashable: Any]) -> Bool {
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
    
    /// Ensures the original AppDelegate is swizzled when using mParticle
    /// or another library that proxies the AppDelegate that way
    func ensureOriginalAppDelegate() {
        if let appDel = appDelegate, String(describing: appDel.self).contains("AppDelegateProxy") {
            let sel = Selector(("originalAppDelegate"))
            let method = class_getInstanceMethod(object_getClass(appDel), sel)
            if let instanceMethod = method {
                let imp = method_getImplementation(instanceMethod)
                typealias OriginalAppDelegateGetter = @convention(c) (AnyObject, Selector) -> UIApplicationDelegate?
                let curriedImplementation: OriginalAppDelegateGetter =
                unsafeBitCast(imp, to: OriginalAppDelegateGetter.self)
                let originalAppDelegate = curriedImplementation(appDel, sel)
                if originalAppDelegate != nil {
                    appDelegate = originalAppDelegate
                }
            }
        }
    }
}
