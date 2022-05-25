//
//  ActionManager+Action.swift
//  Leanplum
//
//  Created by Milos Jakovljevic on 2.01.22.
//  Copyright © 2022 Leanplum. All rights reserved.

import Foundation

extension ActionManager {
    struct Action {
        enum ActionType {
            /// Default action
            case single
            /// Chained to exisiting action
            case chained
            /// Embedded inside existing action
            case embedded
        }

        var type: ActionType = .single
        var context: ActionContext
        
        var notification: Bool {
            context.parent != nil && context.parent?.name == LP_PUSH_NOTIFICATION_ACTION
        }
    }
}

extension ActionManager.Action {
    static func single(context: ActionContext) -> Self {
        .init(type: .single, context: context)
    }
    
    static func chained(context: ActionContext) -> Self {
        .init(type: .chained, context: context)
    }
    
    static func embedded(context: ActionContext) -> Self {
        .init(type: .embedded, context: context)
    }
    
    static func action(context: ActionContext) -> Self {
        if context.parent != nil && !context.isChainedMessage {
            return .embedded(context: context)
        }
        if context.isChainedMessage {
            return .chained(context: context)
        }
        return .single(context: context)
    }
}

