//
//  ActionManager+Triggering.swift
//  Leanplum
//
//  Created by Milos Jakovljevic on 2.01.22.
//

import Foundation

extension ActionManager {
    
    @objc public enum Priority: Int {
        case high
        case `default`
    }

    @objc public func trigger(contexts: [ActionContext], priority: Priority = .default, trigger: ActionsTrigger? = nil) {
        let filteredActions = orderMessages?(contexts, trigger) ?? contexts
        let actions: [Action] = filteredActions.map {
            .action(context: $0)
        }
        switch priority {
            case .high:
                insertActions(actions: actions)
            default:
                appendActions(actions: actions)
        }
    }
    
    @objc public func triggerDelayedMessages() {
        appendActions(actions: delayedQueue.popAll())
    }
}

extension ActionManager {
    enum MessageDisplayChoice {
        case show
        case discard
        case delay(seconds: Int)
    }
    
    @objc public class MessageOrder: NSObject {
        var decision: MessageDisplayChoice = .show
        
        @objc public static func show() -> Self {
            .init(decision: .show)
        }
        
        @objc public static func discard() -> Self {
            .init(decision: .discard)
        }
        
        @objc public static func delay(seconds: Int) -> Self {
            .init(decision: .delay(seconds: seconds))
        }
        
        required init(decision: MessageDisplayChoice) {
            super.init()
            self.decision = decision
        }
    }
}

