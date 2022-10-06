//
//  CTWrapper+Utilities.swift
//  LeanplumSDK
//
//  Created by Nikola Zagorchev on 6.10.22.
//

import Foundation

extension CTWrapper {
    func isAnyNil(_ value: Any) -> Bool {
        if case Optional<Any>.none = value {
            return true
        }
        return false
    }
    
    var transformAttributeValues: ((Any) -> Any) {
        return { value in
            if let arr = value as? Array<Any> {
                let arrString = arr.map {
                    String(describing: $0)
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
