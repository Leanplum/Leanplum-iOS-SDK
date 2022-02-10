//
//  Constants+Device.swift
//  LeanplumSDK
//
//  Copyright (c) 2022 Leanplum, Inc. All rights reserved.
//

import Foundation

extension Constants {
    enum Device {
        enum Leanplum {
            enum Parameter {
                static let pushToken = "iosPushToken"
                static let userNotificationTypes = "iosPushTypes"
                static let userNotificationCategories = "iosPushCategories"
            }
        }
    }
}
