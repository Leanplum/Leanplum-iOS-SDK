//
//  ActionManager+Tracking.swift
//  Leanplum
//
//  Created by Milos Jakovljevic on 2.01.22.
//  Copyright © 2022 Leanplum. All rights reserved.

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
                LPActionTriggerManager.shared().recordChainedActionImpression(action.context.messageId)
            case .message:
                LPActionTriggerManager.shared().recordMessageImpression(action.context.messageId)
            default:
                break
            }
        } else {
            LPActionTriggerManager.shared().recordMessageImpression(action.context.messageId)
        }
    }
}
