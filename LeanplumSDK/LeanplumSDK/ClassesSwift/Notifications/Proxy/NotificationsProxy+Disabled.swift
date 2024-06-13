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

    @objc public func userNotificationCenter(didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        self.leanplum_userNotificationCenter(UNUserNotificationCenter.current(), didReceive: response, withCompletionHandler: completionHandler)
    }

    @objc public func userNotificationCenter(willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        self.leanplum_userNotificationCenter(UNUserNotificationCenter.current(), willPresent: notification, withCompletionHandler: completionHandler)
    }
    
    @objc public func handleActionWithIdentifier(_ identifier: String, forRemoteNotification notification: [AnyHashable:Any]) {
        Leanplum.notificationsManager().notificationOpened(userInfo: notification, action: identifier)
    }
}
