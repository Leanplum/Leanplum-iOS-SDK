//
//  ActionManager+Processor.swift
//  LeanplumSDK
//
//  Created by Nikola Zagorchev on 3.02.22.
//  Copyright © 2022 Leanplum. All rights reserved.

import Foundation

extension ActionManager {
    
    /// Merges in-app messages and actions arguments with default ones from ActionDefinition
    /// Downloads files for action arguments
    @objc public func processMessagesAndDownloadFiles(_ messages: [AnyHashable: Any]) {
        // Set messages
        self.messages = messages
        
        for messageId in messages.keys {
            let messageConfig = messages[messageId] as? [AnyHashable: Any]
            var newConfig = messageConfig
            let actionArgs = messageConfig?[LP_KEY_VARS] as? [AnyHashable: Any] ?? [:]
            let actionName = newConfig?[LP_PARAM_ACTION] as? String
            let definition = self.definitions.first(where: { $0.name == actionName })
            
            guard let definition = definition else {
                // No definition found, use diff
                newConfig?[LP_KEY_VARS] = actionArgs
                self.messages[messageId] = newConfig
                continue
            }

            let defaultArgs = definition.values
            let messageVars = ContentMerger.merge(vars: defaultArgs, diff: actionArgs) as? [AnyHashable: Any] ?? [:]
            newConfig?[LP_KEY_VARS] = messageVars
            self.messages[messageId] = newConfig
            
            downloadFiles(actionArgs: messageVars,
                          defaultValues: defaultArgs,
                          definitionKinds: definition.kinds)
        }
    }
}
