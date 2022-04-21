//
//  ActionManager+FileDownload.swift
//  LeanplumSDK
//
//  Created by Nikola Zagorchev on 21.04.22.
//

import Foundation

extension ActionManager {
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
}
