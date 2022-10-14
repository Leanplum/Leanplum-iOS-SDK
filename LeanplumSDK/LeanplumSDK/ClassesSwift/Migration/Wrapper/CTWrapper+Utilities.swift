//
//  CTWrapper+Utilities.swift
//  LeanplumSDK
//
//  Created by Nikola Zagorchev on 6.10.22.
//  Copyright © 2022 Leanplum. All rights reserved.

import Foundation
// Use @_implementationOnly to *not* expose CleverTapSDK to the Leanplum-Swift header
@_implementationOnly import CleverTapSDK

extension CTWrapper {
    func isAnyNil(_ value: Any) -> Bool {
        if case Optional<Any>.none = value {
            return true
        }
        return false
    }
    
    var transformArrayValues: ((Any) -> Any) {
        return { value in
            if let arr = value as? Array<Any?> {
                let arrString = arr
                    .compactMap{ $0 }
                    .map {
                        String(describing: $0!)
                    }
                return ("[\(arrString.joined(separator: ","))]") as Any
            }
            return value
        }
    }
    
    var transformAttributeKeys: ((AnyHashable) -> AnyHashable) {
        return { key in
            guard let keyStr = key as? String,
            let newKey = MigrationManager.shared.attributeMappings[keyStr]
            else {
                return key
            }

            return newKey
        }
    }
}

extension CleverTapLogLevel {
    init(_ level: LeanplumLogLevel) {
        switch level {
        case .off:
            self = .off
        case .error, .info:
            self = .info
        case .debug:
            self = .debug
        default:
            self = .info
        }
    }
}
