//
//  ActionManager+Triggering.swift
//  LeanplumSDK
//
//  Created by Milos Jakovljevic on 27.09.21.
//

import Foundation

extension ActionManager: ActionSchedulerDelegate {
    
    public func trigger(_ trigger: [String: String], actions: [ActionContext]) {
        let filtered = controllerDelegate?.messageDisplayOrder(trigger: trigger, actions: actions) ?? actions
        addActions(actions: filtered)
    }
    
    public func triggerDelayedMessages() {
        queue.prepareDelayedActions()
        execute()
    }
    
    func onActionDelayed(action: Action) {
        addActions(actions: [action])
    }
}
