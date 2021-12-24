//
//  UNNotificationSettings+Transform.swift
//  LeanplumSDK
//
//  Copyright (c) 2021 Leanplum, Inc. All rights reserved.
//

import Foundation

@available(iOS 10.0, *)
extension UNNotificationSettings {
    func toInt() -> UInt? {
        
        let settings = self
        
        var result: UInt = 0
        
        // Authorization Status
        if #available(iOS 12.0, *) {
            if settings.authorizationStatus == .provisional {
                return UNAuthorizationOptions.provisional.rawValue
            }
        }
        if settings.authorizationStatus == .notDetermined {
            return nil
        }
        if settings.authorizationStatus == .denied {
            return 0
        }
        
        // Authorization Status Enabled
        if settings.soundSetting == .enabled {
            result |= UNAuthorizationOptions.sound.rawValue
        }
        if settings.badgeSetting == .enabled {
            result |= UNAuthorizationOptions.badge.rawValue
        }
        if settings.alertSetting == .enabled {
            result |= UNAuthorizationOptions.alert.rawValue
        }
        if settings.lockScreenSetting == .enabled {
            result |= (1 << 3)
        }
        if settings.notificationCenterSetting == .enabled {
            result |= (1 << 4)
        }
        if #available(iOS 15.0, *) {
            if settings.timeSensitiveSetting == .enabled {
                result |= (1 << 5)
            }
        }
        
        return result
    }
}
