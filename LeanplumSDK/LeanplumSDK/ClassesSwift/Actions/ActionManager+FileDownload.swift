//
//  ActionManager+FileDownload.swift
//  LeanplumSDK
//
//  Created by Nikola Zagorchev on 21.04.22.
//  Copyright © 2022 Leanplum. All rights reserved.

import Foundation

extension ActionManager {
    @objc public static let ActionArgFilePrefix = "__file__"
    
    var downloadFile: (String, String) -> () {
        { value, defaultValue in
            LPFileManager.maybeDownloadFile(value, defaultValue: defaultValue)
        }
    }
    
    @objc public func downloadFiles(actionArgs: [AnyHashable: Any],
                                    defaultValues: [AnyHashable: Any],
                                    definition: ActionDefinition) {
        forEachArg(args: actionArgs, defaultArgs: defaultValues, definitionKinds: definition.kinds) { value, defaultValue in
            downloadFile(value, defaultValue)
        }
    }
    
    /// Download files for action arguments
    /// File args are ActionArgs of Kind File or args with name prefixed with "__file__"
    ///
    /// - Parameters:
    ///     - actionArgs: Action arguments
    ///     - defaultValues: Default action arguments
    ///     - definitionKinds: Action Definition kinds
    @objc public func downloadFiles(actionArgs: [AnyHashable: Any],
                                    defaultValues: [AnyHashable: Any],
                                    definitionKinds: [String: String]) {
        forEachArg(args: actionArgs, defaultArgs: defaultValues, definitionKinds: definitionKinds) { value, defaultValue in
            downloadFile(value, defaultValue)
        }
    }
    
    @objc public func hasMissingFiles(actionArgs: [AnyHashable: Any],
                                      defaultValues: [AnyHashable: Any],
                                      definitionKinds: [String: String]) -> Bool {
        var hasMissingFile = false
        forEachArg(args: actionArgs, defaultArgs: defaultValues, definitionKinds: definitionKinds) { value, defaultValue in
            if LPFileManager.shouldDownloadFile(value, defaultValue: defaultValue) {
                hasMissingFile = true
                return
            }
        }
        return hasMissingFile
    }
    
    /// Iterates recursively all args and executes a callback for each arg that is a file
    /// File args are ActionArgs of Kind File or args with name prefixed with "__file__"
    /// ActionArgs of type Action are merged and their args iterated
    ///
    /// - Parameters:
    ///     - args: Action arguments
    ///     - defaultArgs: Default action arguments
    ///     - definitionKinds: Action Definition kinds
    ///     - fileArgCallback: File argument callback (value, defaultValue)
    ///     - prefix: argument key prefix
    func forEachArg(args: [AnyHashable: Any],
                    defaultArgs: [AnyHashable: Any],
                    definitionKinds: [String: String],
                    fileArgCallback: (_ value: String, _ defaultValue: String) -> (),
                    prefix: String = "") {
        for arg in args {
            let key = arg.key as? String ?? ""
            let value = arg.value as? String ?? ""
            let defaultValue = defaultArgs[arg.key] as? String ?? ""
            let keyWithPrefix = "\(prefix)\(arg.key)"
            let kind = definitionKinds[keyWithPrefix]
            
            if kind == LP_KIND_FILE {
                fileArgCallback(value, defaultValue)
                continue
            }
            
            if key.hasPrefix(ActionManager.ActionArgFilePrefix) {
                fileArgCallback(value, defaultValue)
                continue
            }
            
            if let dict = arg.value as? [AnyHashable: Any] {
                if let actionName = dict[LP_VALUE_ACTION_ARG] as? String {
                    // Argument is an Action
                    if let ac = self.definition(withName: actionName) {
                        let vars = ContentMerger.merge(vars: ac.values, diff: dict) as? [AnyHashable: Any]
                        forEachArg(args: vars ?? [:],
                                   defaultArgs: ac.values,
                                   definitionKinds: ac.kinds,
                                   fileArgCallback: fileArgCallback)
                    }
                } else {
                    forEachArg(args: dict,
                               defaultArgs: defaultArgs[arg.key] as? [AnyHashable: Any] ?? [:],
                               definitionKinds: definitionKinds,
                               fileArgCallback: fileArgCallback,
                               prefix: "\(keyWithPrefix).")
                }
            }
        }
    }
}
