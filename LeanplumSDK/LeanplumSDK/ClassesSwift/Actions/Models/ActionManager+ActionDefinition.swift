//
//  ActionManager+ActionDefinition.swift
//  Leanplum
//
//  Created by Milos Jakovljevic on 2.01.22.
//  Copyright © 2022 Leanplum. All rights reserved.

import Foundation

extension ActionManager {
    @objc public class ActionDefinition: NSObject {
        @objc public let name: String
        public let args: [ActionArg]
        public let kind: LeanplumActionKind
        public let options: [String: String]

        public var presentAction: ((ActionContext) -> (Bool))?
        public var dismissAction: ((ActionContext) -> (Bool))?
        
        /// Nested ActionArgs
        @objc public var values: [AnyHashable: Any] = [:]
        
        /// ActionArgs name and ActionArgs Kind
        @objc public var kinds: [String: String] = [:]
        
        /// ActionArgs name order
        private var order: [String] = []

        @objc public required init(name: String,
                                   args: [Any],
                                   kind: LeanplumActionKind,
                                   options: [String: String],
                                   presentAction: ((ActionContext) -> (Bool))? = nil,
                                   dismissAction: ((ActionContext) -> (Bool))? = nil) {
            self.name = name
            self.args = args as? [ActionArg] ?? [ActionArg]()
            self.kind = kind
            self.options = options
            self.presentAction = presentAction
            self.dismissAction = dismissAction
            
            super.init()
            
            self.processArgs()
        }
        
        fileprivate func processArgs() {
            for arg in self.args {
                order.append(arg.name)
                kinds[arg.name] = arg.kind
                
                // Nest Action args
                // Args: Title.Color, Title.Text, Title.Properties[:]
                // to Values: Title[Text: "", Color: "", Properties: [:]]
                values[stringKeyPath: arg.name] = arg.defaultValue
            }
        }
        
        @objc public var json: [String: Any] {
            return [
                "kind": kind.rawValue,
                "values": values,
                "kinds": kinds,
                "order": order,
                "options": options
            ]
        }
    }
}

extension ActionManager.ActionDefinition {
    @objc public static func action(name: String,
                                    args: [ActionArg] = [],
                                    options: [String: String],
                                    presentAction: ((ActionContext) -> (Bool))? = nil,
                                    dismissAction: ((ActionContext) -> (Bool))? = nil) -> Self {
        .init(name: name,
              args: args,
              kind: .action,
              options: options,
              presentAction: presentAction,
              dismissAction: dismissAction)
    }
    
    @objc public static func message(name: String,
                                     args: [ActionArg] = [],
                                     options: [String: String],
                                     presentAction: ((ActionContext) -> (Bool))? = nil,
                                     dismissAction: ((ActionContext) -> (Bool))? = nil) -> Self {
        .init(name: name,
              args: args,
              kind: .message,
              options: options,
              presentAction: presentAction,
              dismissAction: dismissAction)
    }
}

