//
//  ActionManager+Definition.swift
//  Leanplum
//
//  Created by Milos Jakovljevic on 2.01.22.
//

import Foundation

extension ActionManager {
    
    @objc public func defineAction(definition: ActionDefinition) {
        definitions.append(definition)
    }
    
    @objc public func definition(withName name:String) -> ActionDefinition? {
        return self.definitions.first(where: { $0.name == name })
    }
    
    func getActionDefinitionType(name: String) -> UInt {
        let definition = definition(withName: name)
        if let definition = definition {
            return definition.kind.rawValue
        }
        return 0
    }
}
