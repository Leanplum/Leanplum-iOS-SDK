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
        VarCache.shared().registerActionDefinition(definition.name,
                                                     ofKind: Int32(definition.kind.rawValue),
                                                     withArguments: definition.args,
                                                     andOptions: definition.options)
    }
}
