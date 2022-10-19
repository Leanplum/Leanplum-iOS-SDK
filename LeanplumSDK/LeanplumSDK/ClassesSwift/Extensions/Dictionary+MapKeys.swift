//
//  Dictionary+MapKeys.swift
//  LeanplumSDK
//
//  Created by Nikola Zagorchev on 6.10.22.
//  Copyright © 2022 Leanplum. All rights reserved.

import Foundation

extension Dictionary {
    /// Transforms dictionary keys without modifying values.
    /// Deduplicates transformed keys, by choosing the first value.
    ///
    /// Example:
    /// ```
    /// ["one": 1, "two": 2, "three": 3, "": 4].mapKeys({ $0.first })
    /// // [Optional("o"): 1, Optional("t"): 2, nil: 4]
    /// ```
    ///
    /// - Parameters:
    ///   - transform: A closure that accepts each key of the dictionary as
    ///   its parameter and returns a transformed key of the same or of a different type.
    /// - Returns: A dictionary containing the transformed keys and values of this dictionary.
    func mapKeys<T>(_ transform: (Key) throws -> T) rethrows -> [T: Value] {
        try .init(map { (try transform($0.key), $0.value) },
                  uniquingKeysWith: { (a, b) in a })
    }
    
    /// Transforms dictionary keys without modifying values.
    /// Deduplicates transformed keys.
    ///
    /// Example:
    /// ```
    /// ["one": 1, "two": 2, "three": 3, "": 4].mapKeys({ $0.first }, uniquingKeysWith: { max($0, $1) })
    /// // [Optional("o"): 1, Optional("t"): 3, nil: 4]
    /// ```
    /// Credits:  https://forums.swift.org/t/mapping-dictionary-keys/15342/4
    ///
    /// - Parameters:
    ///   - transform: A closure that accepts each key of the dictionary as
    ///   its parameter and returns a transformed key of the same or of a different type.
    ///   - combine:A closure that is called with the values for any duplicate
    ///   keys that are encountered. The closure returns the desired value for
    ///   the final dictionary.
    /// - Returns: A dictionary containing the transformed keys and values of this dictionary.
    func mapKeys<T>(_ transform: (Key) throws -> T, uniquingKeysWith combine: (Value, Value) throws -> Value) rethrows -> [T: Value] {
        try .init(map { (try transform($0.key), $0.value) }, uniquingKeysWith: combine)
    }
}
