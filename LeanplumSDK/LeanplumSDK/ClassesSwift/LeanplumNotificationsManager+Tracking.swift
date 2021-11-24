//
//  LeanplumNotificationsManager+Tracking.swift
//  LeanplumSDK
//
//  Created by Nikola Zagorchev on 17.11.21.
//  Copyright © 2021 Leanplum. All rights reserved.

import Foundation

extension LeanplumNotificationsManager {
    
    public static var isPushDeliveryTrackingEnabled = true
    
    func trackDelivery(userInfo:[AnyHashable:Any]) {
        guard LeanplumNotificationsManager.isPushDeliveryTrackingEnabled else {
            LeanplumUtils.lpLog(type: .debug, format: "Push delivery tracking is disabled")
            return
        }
        
        // We cannot consistently track delivery for local notifications
        // Do not track
        guard userInfo[LP_KEY_LOCAL_NOTIF] == nil else {
            return
        }
        
        var args = [String:Any]()
        args[LP_KEY_PUSH_METRIC_MESSAGE_ID] = LeanplumUtils.messageIdFromUserInfo(userInfo)
        args[LP_KEY_PUSH_METRIC_OCCURRENCE_ID] = userInfo[LP_KEY_PUSH_OCCURRENCE_ID]
        args[LP_KEY_PUSH_METRIC_SENT_TIME] = userInfo[LP_KEY_PUSH_SENT_TIME] ?? Date().timeIntervalSince1970
        args[LP_KEY_PUSH_METRIC_CHANNEL] = DEFAULT_PUSH_CHANNEL
        
        Leanplum.track(PUSH_DELIVERED_EVENT_NAME, params: args)
    }
}
