//
//  ActionManager+Triggering.swift
//  LeanplumSDK
//
//  Created by Milos Jakovljevic on 27.09.21.
//

import Foundation

extension ActionManager: ActionSchedulerDelegate {
    
    @objc public enum Priority: Int {
        case high
        case `default`
    }
    
    @objc public func trigger(actionContexts: [ActionContext]) {
        let filteredActions = sortAndOrderMessages?(actionContexts, [:]) ?? actionContexts
        addActions(contexts: filteredActions)
    }
    
    @objc public func trigger(actionContexts: [ActionContext], priority: Priority = .default) {
        let filteredActions = sortAndOrderMessages?(actionContexts, [:]) ?? actionContexts
        switch priority {
        case .high:
            insertActions(contexts: filteredActions)
        default:
            appendActions(contexts: filteredActions)
        }
    }
    
    // refactor to use struct/class
    @objc public func trigger(actionContexts: [ActionContext], trigger: [String: String]? = nil) {
        let filteredActions = sortAndOrderMessages?(actionContexts, [:]) ?? actionContexts
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
