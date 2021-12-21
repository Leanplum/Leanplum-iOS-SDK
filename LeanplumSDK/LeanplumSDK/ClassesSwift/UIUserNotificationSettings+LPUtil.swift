//
//  UIUserNotificationSettings+LPUtil.swift
//  LeanplumSDK
//
//  Copyright (c) 2021 Leanplum, Inc. All rights reserved.
//

import Foundation

extension UIUserNotificationSettings {
    var dictionary: [AnyHashable: Any] {
        let types = self.types
        var categories: [UIUserNotificationCategory] = []
        if let tmpCategories = self.categories {
            for category in tmpCategories {
                if category.identifier != nil {
                    categories.append(category)
                }
            }
        }
        let sortedCategories = categories.sorted { (lhs: UIUserNotificationCategory, rhs: UIUserNotificationCategory) -> Bool in
            return lhs.identifier?.caseInsensitiveCompare(rhs.identifier ?? "") == .orderedAscending
        }
        let settings = [
            LP_PARAM_DEVICE_USER_NOTIFICATION_TYPES: types.rawValue,
            LP_PARAM_DEVICE_USER_NOTIFICATION_CATEGORIES: sortedCategories
        ] as [AnyHashable : Any]
        return settings
    }
}
