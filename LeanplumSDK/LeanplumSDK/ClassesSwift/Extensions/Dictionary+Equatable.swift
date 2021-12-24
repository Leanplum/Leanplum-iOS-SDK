//
//  Dictionary+Equatable.swift
//  LeanplumSDK
//
//  Copyright (c) 2021 Leanplum, Inc. All rights reserved.
//

import Foundation

extension Dictionary {
    func isEqual(_ dictionary: [AnyHashable: Any]) -> Bool {
        return NSDictionary(dictionary: self).isEqual(to: dictionary)
    }
}
