//
//  ActionManager+VarCache.swift
//  LeanplumSDK
//
//  Created by Nikola Zagorchev on 3.02.22.
//

import Foundation

extension ActionManager {

    @objc public func updateMessages(_ messages: [AnyHashable: Any]) {
        messagesDataFromServer = messages

        for messageId in messages.keys {
            let messageConfig = messages[messageId] as? [AnyHashable:Any]
            var newConfig = messageConfig
            let actionArgs = messageConfig?[LP_KEY_VARS]
            let actionName = newConfig?[LP_PARAM_ACTION] as? String
            
            guard let actionName = actionName else {
                let messageVars = merge(vars: [:], diff: actionArgs ?? [:])
                newConfig?[LP_KEY_VARS] = messageVars
                self.messages[messageId] = newConfig
                continue
            }
            
            let definition = self.definitions.first(where: { $0.name == actionName })
            let defaultArgs = definition?.values

            let messageVars = VarCache.shared().mergeHelper(defaultArgs ?? [:], withDiffs: actionArgs ?? [:])
            newConfig?[LP_KEY_VARS] = messageVars
            self.messages[messageId] = newConfig
            
            downloadFiles(messageArgs: messageVars as? [AnyHashable : Any] ?? [:],
                          defaultValues: defaultArgs ?? [:],
                          definitionKinds: definition?.kinds ?? [:])
        }
    }
    
    @objc public func definition(withName name:String) -> ActionDefinition? {
        return self.definitions.first(where: { $0.name == name })
    }

    @objc public func downloadFiles(messageArgs: [AnyHashable: Any], defaultValues: [AnyHashable: Any], definitionKinds: [String: String]) {
        forEachArg(prefix: "", args: messageArgs, defaultArgs: defaultValues, definitionKinds: definitionKinds) { value, defaultValue in
            LPFileManager.maybeDownloadFile(value, defaultValue: defaultValue)
        }
    }
    
    @objc public func hasMissingFiles(messageArgs: [AnyHashable: Any], defaultValues: [AnyHashable: Any], definitionKinds: [String: String]) -> Bool {
        var hasMissingFile = false
        forEachArg(prefix: "", args: messageArgs, defaultArgs: defaultValues, definitionKinds: definitionKinds) { value, defaultValue in
            if LPFileManager.shouldDownloadFile(value, defaultValue: defaultValue) {
                hasMissingFile = true
                return
            }
        }
        return hasMissingFile
    }
    
    func forEachArg(prefix: String, args: [AnyHashable: Any], defaultArgs: [AnyHashable: Any], definitionKinds: [String: String], callback: (String, String) -> ()) {
            for arg in args {
                let key = arg.key as? String ?? ""
                let value = arg.value as? String ?? ""
                let defaultValue = defaultArgs[arg.key] as? String ?? ""
                let keyWithPrefix = "\(prefix)\(arg.key)"
                let kind = definitionKinds[keyWithPrefix]
                
                if kind == LP_KIND_FILE {
                    callback(value, defaultValue)
                    return
                }
                
                if key.hasPrefix("__file__") {
                    callback(value, defaultValue)
                    return
                }

                if let dict = arg.value as? [AnyHashable: Any] {
                    if let actionName = dict[LP_VALUE_ACTION_ARG] as? String {
                        let ac = self.definition(withName: actionName)
                        if let ac = ac {
                            let vars = merge(vars: ac.values, diff: dict) as? [AnyHashable: Any]
                            forEachArg(prefix: "",
                                       args: vars ?? [:],
                                       defaultArgs: ac.values,
                                       definitionKinds: ac.kinds,
                                       callback: callback)
                        }
                    } else {
                        forEachArg(prefix: "\(keyWithPrefix).",
                                   args: dict,
                                   defaultArgs: defaultArgs[arg.key] as? [AnyHashable : Any] ?? [:],
                                   definitionKinds: definitionKinds,
                                   callback: callback)
                    }
                }
            }
        }
    

    @objc public func merge(vars: Any, diff: Any) -> Any {
        if let diff = diff as? NSNumber {
            return diff
        }
        if let diff = diff as? String {
            return diff
        }
        if let diff = diff as? NSNull {
            return diff
        }
        
        if vars is NSNumber ||
            vars is String ||
            vars is NSNull {
            return diff
        }
        
        // Merge Arrays
        let isVarsArray = isArray(original: vars, diff: diff)
        if vars is Array<Any> || isVarsArray {
            var merged: [Any] = []
            if let varsArr = vars as? [Any] {
                // Add all default args
                merged.append(contentsOf: varsArr)
            }
           
            // Merge values from server
            // Array values from server come as Dictionary
            // Example:
            // string[] items = new string[] { "Item 1", "Item 2"};
            // args.With<string[]>("Items", items); // Action Context arg value
            // "vars": {
            //      "Items": {
            //                  "[1]": "Item 222", // Modified value from server
            //                  "[0]": "Item 111"  // Modified value from server
            //              }
            //  }
            if let diffDict = diff as? [AnyHashable: Any] {
                for key in diffDict.keys {
                    guard let keyStr = key as? String else {
                        continue
                    }
                    let i = index(fromKey: keyStr)
                    guard i != -1 else {
                        continue
                    }
                    
                    let newValue = diffDict[keyStr] ?? NSNull()
                    // value index is bigger than default array count
                    // the value is a new one, append it to the array
                    if merged.count <= i {
                        merged.append(merge(vars: merged[i], diff: newValue))
                    } else {
                        // the new value overrides existing value at index
                        merged[i] = merge(vars: merged[i], diff: newValue)
                    }
                }
            }
            return merged
        }
        
        // Merge Dictionaries
        var merged: [AnyHashable: Any] = [:]
        
        if let varsDict = vars as? [AnyHashable: Any] {
            merged = varsDict
        }
        
        if let diffDict = diff as? [AnyHashable: Any] {
            diffDict.forEach { key, value in
                merged[key] = merge(vars: merged[key] ?? [:], diff: value)
            }
            
            return merged
        }
        
        return NSNull() //Optional<Any>.none as Any //NSNull()
    }
    
    var pattern: String {
        return "^(\\[[1-9]\\d*\\]|\\[0\\])$"
    }
    
    var regex: NSRegularExpression {
        return try! NSRegularExpression(pattern: pattern)
    }
    
    func index(fromKey key: String) -> Int {
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
    
    func isArray(original: Any?, diff: Any?) -> Bool {
        if original == nil {
            if let diffDict = diff as? [AnyHashable: Any], diffDict.count > 0 {
                // format: "[0]", "[1]", ... "[99]" ... etc
                let anyNotMatchingFormat = diffDict.first(where: { key, value in
                    return regex.matches(key as? String)
                })
                // if any element does not match format, return false
                return anyNotMatchingFormat == nil
            }
        }
        
        return false
    }
}

extension NSRegularExpression {
    func matches(_ string: String?) -> Bool {
        guard let string = string else {
            return false
        }

        let range = NSRange(location: 0, length: string.utf16.count)
        return firstMatch(in: string, options: [], range: range) != nil
    }
}
