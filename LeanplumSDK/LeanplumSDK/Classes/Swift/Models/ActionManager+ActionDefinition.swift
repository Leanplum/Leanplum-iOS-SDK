//
//  ActionManager+ActionDefinition.swift
//  LeanplumSDK
//
//  Created by Milos Jakovljevic on 21.12.21.
//

import Foundation

extension ActionManager {
    @objc public class ActionDefinition: NSObject {
        public let name: String
        public let args: [ActionArg]
        public let kind: Leanplum.ActionKind
        public let options: [String: String]
        
        public var presentAction: ((ActionContext) -> (Bool))?
        public var dismissAction: ((ActionContext) -> (Bool))?
        
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
        
        @objc public required init(name: String,
                                   args: [ActionArg],
                                   kind: Leanplum.ActionKind,
                                   options: [String: String],
                                   presentAction: ((ActionContext) -> (Bool))? = nil,
                                   dismissAction: ((ActionContext) -> (Bool))? = nil) {
            self.name = name
            self.args = args
            self.kind = kind
            self.options = options
            self.presentAction = presentAction
            self.dismissAction = dismissAction
            
            super.init()
        }
    }
}
