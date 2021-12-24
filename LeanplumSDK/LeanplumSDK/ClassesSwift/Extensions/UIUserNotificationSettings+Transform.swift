//
//  UIUserNotificationSettings+Transform.swift
//  LeanplumSDK
//
//  Copyright (c) 2021 Leanplum, Inc. All rights reserved.
//

import Foundation

extension UIUserNotificationSettings {
    var dictionary: [AnyHashable: Any] {
        let types = self.types
        var categories: [String] = []
        if let tmpCategories = self.categories {
            for category in tmpCategories {
                if let categoryIdentifier = category.identifier {
                    categories.append(categoryIdentifier)
                }
            }
        }
        let sortedCategories = categories.sorted { (lhs: String, rhs: String) -> Bool in
            return lhs.caseInsensitiveCompare(rhs) == .orderedAscending
        }
        let settings = [
            LP_PARAM_DEVICE_USER_NOTIFICATION_TYPES: types.rawValue,
            LP_PARAM_DEVICE_USER_NOTIFICATION_CATEGORIES: sortedCategories
        ] as [AnyHashable: Any]
        return settings
    }
}
