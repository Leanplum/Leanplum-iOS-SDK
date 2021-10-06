//
//  ActionManager+Definition.swift
//  LeanplumSDK
//
//  Created by Milos Jakovljevic on 20.09.21.
//

import Foundation

extension ActionManager {
    
    struct Definitions {
        var actionDefinitions: [ActionDefinition] = []
    }

    public struct ActionDefinition {
        
        public enum Kind {
            case action
            case message
        }
        
        let name: String
        let args: [ActionArg]
        let kind: Kind
        
        var present: ((ActionContext) -> (Bool))?
    }
    
    public func defineAction(definition: ActionDefinition) {
        definitions.actionDefinitions.append(definition)
    }
}
