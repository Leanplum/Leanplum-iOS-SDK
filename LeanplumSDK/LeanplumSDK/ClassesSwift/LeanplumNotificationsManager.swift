//
//  LeanplumNotificationsManager.swift
//  LeanplumSDK
//
//  Created by Nikola Zagorchev on 28.10.21.
//  Copyright © 2021 Leanplum. All rights reserved.

import Foundation

/// Manager responsible for handling push (remote) and local notifications
@objc public class LeanplumNotificationsManager: NSObject {
    
    @objc public var proxy: LeanplumPushNotificationsProxy
    
    @objc public override init() {
        proxy = LeanplumPushNotificationsProxy()
    }
}
