//
//  ActionManager+Tracking.swift
//  Leanplum
//
//  Created by Milos Jakovljevic on 2.01.22.
//

import Foundation

extension ActionManager {
    func recordImpression(action: Action) {
        typealias Kind = Leanplum.ActionKind
        if action.type == .chained {
            // We do not want to count occurrences for action kind, because in multi message
            // campaigns the Open URL action is not a message. Also if the user has defined
            // actions of type Action we do not want to count them.
            
            let actionKind: Kind = .init(rawValue: getActionDefinitionType(name: action.context.name))
            switch actionKind {
                case .action:
                    LPActionManager.shared().recordChainedActionImpression(action.context.messageId)
                case .message:
                    LPActionManager.shared().recordMessageImpression(action.context.messageId)
                default:
                    break
            }
        } else {
            LPActionManager.shared().recordMessageImpression(action.context.messageId)
        }
    }
}
