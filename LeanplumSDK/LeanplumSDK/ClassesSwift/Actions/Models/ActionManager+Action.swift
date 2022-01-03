//
//  ActionManager+Action.swift
//  Leanplum
//
//  Created by Milos Jakovljevic on 2.01.22.
//

import Foundation

extension ActionManager {
    struct Action {
        enum State {
            case queued
            case delayed
            case executing
            case completed
        }

        enum ActionType {
            case chained
            case single
        }

        var state: State
        var type: ActionType = .single
        var context: ActionContext

        static func single(state: State, context: ActionContext) -> Self {
            .init(state: state,
                  type: .single,
                  context: context)
        }

        static func chained(state: State, context: ActionContext) -> Self {
            .init(state: state,
                  type: .chained,
                  context: context)
        }

        static func action(context: ActionContext) -> Self {
            if context.isChainedMessage {
                return .chained(state: .queued, context: context)
            }
            return .single(state: .queued, context: context)
        }
    }
}

