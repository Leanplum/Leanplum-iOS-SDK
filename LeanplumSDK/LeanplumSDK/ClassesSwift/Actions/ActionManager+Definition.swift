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
        // TODO: Register in VarCache this definition so it can be diffend and synced
    }
}
