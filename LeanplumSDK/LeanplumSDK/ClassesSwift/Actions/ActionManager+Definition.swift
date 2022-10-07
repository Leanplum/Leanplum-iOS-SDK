//
//  ActionManager+Definition.swift
//  Leanplum
//
//  Created by Nikola Zagorchev on 2.01.22.
//  Copyright © 2022 Leanplum. All rights reserved.

import Foundation

extension ActionManager {
    
    @objc public func defineAction(definition: ActionDefinition) {
        definitions.append(definition)
    }
    
    @objc public func definition(withName name: String) -> ActionDefinition? {
        return self.definitions.first(where: { $0.name == name })
    }
}
