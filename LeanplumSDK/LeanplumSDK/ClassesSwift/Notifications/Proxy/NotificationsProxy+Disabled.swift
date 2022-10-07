//
//  NotificationsProxy+Disabled.swift
//  LeanplumSDK
//
//  Created by Nikola Zagorchev on 23.12.21.
//  Copyright © 2021 Leanplum. All rights reserved.

import Foundation

extension NotificationsProxy {
    
    @objc public func applicationDidFinishLaunching(launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        if let launchOptions = launchOptions {
            self.applicationLaunched(launchOptions: launchOptions)
        }
    }
    
    @objc public func didReceiveRemoteNotification(userInfo: [AnyHashable: Any], fetchCompletionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
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
    
    @available(iOS, deprecated: 10.0)
    @objc public func application(didReceive notification: UILocalNotification) {
        self.leanplum_application(UIApplication.shared, didReceive: notification)
    }
    
    @objc public func handleActionWithIdentifier(_ identifier: String, forRemoteNotification notification: [AnyHashable:Any]) {
        Leanplum.notificationsManager().notificationOpened(userInfo: notification, action: identifier)
    }
    
    @available(iOS, deprecated: 10.0)
    @objc public func handleActionWithIdentifier(_ identifier: String, forLocalNotification notification: UILocalNotification) {
        if let userInfo = notification.userInfo {
            Leanplum.notificationsManager().notificationOpened(userInfo: userInfo, action: identifier)
        }
    }
}
