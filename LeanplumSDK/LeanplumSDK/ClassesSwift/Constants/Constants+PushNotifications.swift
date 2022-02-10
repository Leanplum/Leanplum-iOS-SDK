//
//  Constants.swift
//  LeanplumSDK
//
//  Copyright (c) 2022 Leanplum, Inc. All rights reserved.
//

import Foundation

enum Constants {
    
    enum PushNotifications {
        
        static let pushNotificationAction = "__Push Notification"
        static let defaultPushAction = "Open action"
        static let deliveredEventName = "Push Delivered"
        static let pushChannel = "APNS"
        
        enum Defaults {
            static let askedToPush = "__Leanplum_asked_to_push"
            static let leanplumEnabledPush = "__Leanplum_enabled_push"
            static let pushTokenKey = "__leanplum_push_token_%@-%@-%@"
        }
        
        enum Keys {
            static let messageId = "_lpm"
            static let muteInApp = "_lpu"
            static let noAction = "_lpn"
            static let noActionMute = "_lpv"
            static let action = "_lpx"
            static let customActions = "_lpc"
            static let occurrenceId = "lp_occurrence_id"
            static let sentTime = "lp_sent_time"
        }
        
        enum Metric {
            static let sentTime = "sentTime"
            static let occurrenceId = "occurrenceId"
            static let channel = "channel"
            static let messageId = "messageID"
        }
    }
    
    enum LocalNotifications {
        static let localNotificationKey = "_lpl"
    }
}
