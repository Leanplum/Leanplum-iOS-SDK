//
//  ActionManager+ActionDefinition.swift
//  Leanplum
//
//  Created by Milos Jakovljevic on 2.01.22.
//

import Foundation

extension ActionManager {
    @objc public class ActionDefinition: NSObject {
        @objc public let name: String
        public let args: [ActionArg]
        public let kind: Leanplum.ActionKind
        public let options: [String: String]

        public var presentAction: ((ActionContext) -> (Bool))?
        public var dismissAction: ((ActionContext) -> (Bool))?
        
        // Title.Color
        // Title.Text
        // Title.Properties -> Dict
        // Title { Text: "", Color: "", Properties: { ... }}
        
        // Title.Action -> Action
        // Title.Action.__name__ = ""
        // Title.Action.Title = ""
        @objc public var values: [AnyHashable:Any] = [:]
        
        @objc public var kinds: [String:String] = [:]
        private var order: [String] = []

        @objc public static func action(name: String,
                                        args: [Any] = [],
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
                                         args: [Any] = [],
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

        @objc public required init(name: String,
                                   args: [Any],
                                   kind: Leanplum.ActionKind,
                                   options: [String: String],
                                   presentAction: ((ActionContext) -> (Bool))? = nil,
                                   dismissAction: ((ActionContext) -> (Bool))? = nil) {
            self.name = name
            if let actionArgs = args as? [ActionArg]{
                self.args = actionArgs
            } else {
                self.args = []
            }
            self.kind = kind
            self.options = options
            self.presentAction = presentAction
            self.dismissAction = dismissAction
            
            for arg in self.args {
                order.append(arg.name)
                kinds[arg.name] = arg.kind
                values[stringKeyPath: arg.name] = arg.defaultValue
            }
            
            super.init()
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

