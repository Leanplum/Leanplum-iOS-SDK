//
//  ContentMerger.swift
//  LeanplumSDK
//
//  Created by Nikola Zagorchev on 18.05.22.
//  Copyright © 2022 Leanplum. All rights reserved.

import Foundation

@objc public class ContentMerger: NSObject {
    typealias AnyDictionary = [AnyHashable: Any]
    
    class var pattern: String {
        "^(\\[[1-9]\\d*\\]|\\[0\\])$"
    }
    
    class var regex: NSRegularExpression {
        try! NSRegularExpression(pattern: pattern)
    }
    
    /// Merges two values together - default and override.
    /// For primitive types override is returned,
    /// Dictionaries are merged and same keys are overridden,
    /// Array overrides come as dictionary with indices and
    /// are merged with default array values, (array and array cannot be merged).
    ///
    /// - Note:
    ///     Currently action arguments are created and represented in objc
    ///     API data is also serialized through NSSerialization in objc
    ///     nil values come as NSNull
    ///     In the future, Optional (Any?) can used for parameters and return type or wrap it as  Optional<Any>.none as Any
    ///     Implementation mimics VarCache mergeHelper
    ///
    /// - Parameters:
    ///     - vars: The default value
    ///     - diff: The override value
    /// - Returns: The product of merging default and override values
    @objc public class func merge(vars: Any, diff: Any) -> Any {
        // Return the modified value if it is a `primitive`
        switch diff {
        case let str as String:
            return str
        case let num as NSNumber:
            return num
        case let n as NSNull:
            return n
        default:
            break
        }
        
        if vars is NSNumber ||
            vars is String {
            return diff
        }
        
        // Merge Arrays
        var isVarsArray = false
        // Infer that the diffs is an array
        // if the vars value doesn't exist to tell us the type
        if vars is NSNull {
            isVarsArray = isArray(value: diff)
        }
        if vars is Array<Any> || isVarsArray {
            var merged: [Any] = []
            if let varsArr = vars as? [Any] {
                // Add all default args
                merged.append(contentsOf: varsArr)
            }
            
            /** Array values from server come as Dictionary
                Example:
                string[] items = new string[] { "Item 1", "Item 2"};
                args.With<string[]>("Items", items); // Action Context arg value
                "vars": {
                    "Items": {
                                "[1]": "Item 222", // Modified value from server
                                "[0]": "Item 111"  // Modified value from server
                            }
                }
             */
            if let diffDict = diff as? AnyDictionary {
                for key in diffDict.keys {
                    guard let keyStr = key as? String else {
                        continue
                    }
                    
                    let i = index(fromKey: keyStr)
                    guard i != -1 else {
                        continue
                    }
                    
                    let newValue = diffDict[keyStr] ?? NSNull()
                    // Value index is bigger than default array count
                    // Fill the array with null values
                    if i >= merged.count {
                        while i >= merged.count {
                            merged.append(NSNull())
                        }
                    }
                    
                    // Override the default value at index
                    merged[i] = merge(vars: merged[i], diff: newValue)
                }
            }
            return merged
        }
        
        // Merge Dictionaries
        var merged: AnyDictionary = [:]
        
        if let varsDict = vars as? AnyDictionary {
            merged = varsDict
        }
        
        if let diffDict = diff as? AnyDictionary {
            diffDict.forEach { key, value in
                let defaultValue = merged[key] ?? NSNull()
                merged[key] = merge(vars: defaultValue, diff: value)
            }
            return merged
        }
        
        return NSNull()
    }
    
    class func index(fromKey key: String) -> Int {
        if regex.matches(key) {
            let start = key.index(key.startIndex, offsetBy: 1)
            let end = key.index(key.endIndex, offsetBy: -2)
            let index = key[start...end]
            guard let i = Int(index) else {
                return -1
            }
            return i
        }
        return -1
    }
    
    /// Infers if a dictionary is an array
    /// if all indices are in the format "[0]", "[1]", ... "[99]"
    ///  - Parameters:
    ///     - value: The object to test for.
    ///  - Returns: ``true`` if dictionary is an array, otherwise false
    class func isArray(value: Any?) -> Bool {
        if let arrDict = value as? AnyDictionary, arrDict.count > 0 {
            // format: "[0]", "[1]", ... "[99]" ... etc
            let anyNotMatchingFormat = arrDict.first(where: { key, value in
                return regex.matches(key as? String)
            })
            // if any element does not match format, return false
            return anyNotMatchingFormat != nil
        }
        
        return false
    }
}
