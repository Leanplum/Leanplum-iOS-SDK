//
//  ActionManager+Triggering.swift
//  Leanplum
//
//  Created by Milos Jakovljevic on 2.01.22.
//  Copyright © 2023 Leanplum. All rights reserved.

import Foundation

extension ActionManager {
    
    @objc public enum Priority: Int, Equatable, Hashable, RawRepresentable {
        case high
        case `default`
        
        var name: String {
            switch self {
            case .high:
                return "high"
            default:
                return "default"
            }
        }
    }
    
    @objc public func trigger(contexts: [Any], priority: Priority = .default, trigger: ActionsTrigger? = nil) {
        guard let contexts = contexts as? [ActionContext] else {
            return
        }
        
        // Return if contexts is empty
        guard let firstContext = contexts.first else {
            return
        }
        
        // By default, add only one message to queue if `prioritizeMessages` is not implemented
        // This ensures backwards compatibility
        prioritizeMessages(contexts: contexts, defaultContexts: [firstContext], trigger: trigger) { [self] filteredActions in
            let actions: [Action] = filteredActions.map {
                .action(context: $0)
            }
            
            Log.debug("[ActionManager]: triggering actions with priority: \(priority.name).")
            
            switch priority {
            case .high:
                self.insertActions(actions: actions)
            default:
                self.appendActions(actions: actions)
            }
        }
    }
    
    func prioritizeMessages(contexts: [ActionContext], defaultContexts: [ActionContext], trigger: ActionsTrigger? = nil, callback: @escaping ([ActionContext]) -> ()) {
        if useAsyncHandlers {
            actionQueue.async { [weak self] in
                let filteredActions = self?.prioritizeMessages?(contexts, trigger) ?? defaultContexts
                DispatchQueue.main.async {
                    callback(filteredActions)
                }
            }
        } else {
            let filteredActions = self.prioritizeMessages?(contexts, trigger) ?? defaultContexts
            callback(filteredActions)
        }
    }
    
    /// Triggers all postponed messages when indefinite time was used with `MessageDisplayChoice`
    @objc public func triggerDelayedMessages() {
        appendActions(actions: delayedQueue.popAll())
    }
}

extension ActionManager {
    enum MessageDisplay {
        case show
        case discard
        /// Delay with seconds: 0 to delay indefinitely
        case delay(seconds: Int)
    }
    
    @objc public class MessageDisplayChoice: NSObject {
        var decision: MessageDisplay = .show
        
        @objc public static func show() -> Self {
            .init(decision: .show)
        }
        
        @objc public static func discard() -> Self {
            .init(decision: .discard)
        }
        
        @objc public static func delay(seconds: Int) -> Self {
            .init(decision: .delay(seconds: seconds))
        }
        
        /// Delays the action indefinitely - until `triggerDelayedMessages` is called
        @objc public static func delayIndefinitely() -> Self {
            .init(decision: .delay(seconds: 0))
        }
        
        required init(decision: MessageDisplay) {
            super.init()
            self.decision = decision
        }
    }
}
