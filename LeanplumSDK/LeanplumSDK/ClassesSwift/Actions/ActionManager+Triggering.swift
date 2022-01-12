//
//  ActionManager+Triggering.swift
//  Leanplum
//
//  Created by Milos Jakovljevic on 2.01.22.
//

import Foundation

extension ActionManager: ActionSchedulerDelegate {

    @objc public enum Priority: Int {
        case high
        case `default`
    }

    @objc public func trigger(actionContexts: [ActionContext]) {
        let filteredActions = sortAndOrderMessages?(actionContexts, nil) ?? actionContexts
        addActions(contexts: filteredActions)
    }

    @objc public func trigger(actionContexts: [ActionContext], priority: Priority = .default) {
        let filteredActions = sortAndOrderMessages?(actionContexts, nil) ?? actionContexts
        switch priority {
        case .high:
            insertActions(contexts: filteredActions)
        default:
            appendActions(contexts: filteredActions)
        }
    }

    @objc public func trigger(actionContexts: [ActionContext], trigger: ActionsTrigger? = nil) {
        let filteredActions = sortAndOrderMessages?(actionContexts, trigger) ?? actionContexts
        addActions(contexts: filteredActions)
    }

    @objc public func triggerDelayedMessages() {
        queue.prepareActions()
    }

    func onActionDelayed(context: ActionContext) {
        appendActions(contexts: [context])
    }
}

extension ActionManager {
    enum MessageDisplayOrder {
        case show
        case discard
        case delay(seconds: Int)
    }

    @objc public class MessageOrder: NSObject {
        var decision: MessageDisplayOrder = .show

        @objc public static func show() -> Self {
            .init(decision: .show)
        }

        @objc public static func discard() -> Self {
            .init(decision: .discard)
        }

        @objc public static func delay(seconds: Int) -> Self {
            .init(decision: .delay(seconds: seconds))
        }

        required init(decision: MessageDisplayOrder) {
            super.init()
            self.decision = decision
        }
    }
}

