//
//  ActionManager+Definition.swift
//  LeanplumSDK
//
//  Created by Milos Jakovljevic on 20.09.21.
//

import Foundation

extension ActionManager {
    @objc public func defineAction(definition: ActionDefinition) {
        definitions.append(definition)
        // TODO: Register in VarCache this definition so it can be diffend and synced
    }
}
