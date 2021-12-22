//
//  ActionManager+Execution.swift
//  LeanplumSDK
//
//  Created by Milos Jakovljevic on 21.09.21.
//

import Foundation

extension ActionManager {
    @objc public func performActions() {
        // ask user to dimiss current action so we can execute next one
        if let action = state.currentAction {
            let definition = definitions.first { $0.name == action.context.name }
            let _ = definition?.dismissAction?(action.context)
            state.currentAction = nil
            performActions()
            return
        }
        
        // gets the next action from the queue
        state.currentAction = queue.pop()
        guard var action = state.currentAction else {
            return
        }
        // change state to executing
        action.state = .executing
        
        // decide if we are going to display the message
        // by calling delegate and let it decide what are we supposed to do
        
        let messageDisplayDecision = shouldDisplayMessage?(action.context)
        
        // if message is discarded, early exit
        if case .discard = messageDisplayDecision?.decision {
            state.currentAction = nil
            performActions()
            return
        }
        
        // if message is delayed, add it to the scheduler to be delayed
        // by the amount of seconds, and exit
        if case .delay(let amount) = messageDisplayDecision?.decision {
            if amount > 0 {
                scheduler.schedule(action: action, delay: amount)
            } else {
                state.currentAction?.state = .delayed
                appendActions(contexts: [action.context])
            }
            state.currentAction = nil
            performActions()
            return
        }
        
        // logic:
        // 1) ask client to show view controller
        // 2) ask and wait for client to execute action
        // 3) ask and wait for client to dismiss view controller
        
        // get the action definition
        let definition = definitions.first { $0.name == action.context.name }
        
        // 2) set the execute block which will be called by client
        action.context.onActionExecuted = { [weak self] actionName, tracked in
            self?.onMessageAction?(actionName, action.context)
        }
        
        // 3) set the dismiss block which will be called by client
        action.context.onActionDismissed = { [weak self] in
            self?.onMessageDismissed?(action.context)
        }
        
        // 1) ask to present, return if its not
        guard let handled = definition?.presentAction?(action.context), handled else {
            state.currentAction = nil
            performActions()
            return
        }
        // iff handled track that message has been displayed
        // propagate event that message is displayed
        onMessageDisplayed?(action.context)
        
        if action.context.name == LP_PUSH_NOTIFICATION_ACTION {
            // do something
        }
        
        if action.type == .chained /* && messageType == action*/ {
            //  TODO: track the chained message impressionn
        }
        
        // record the impression
        recordImpression(action: action)
    }
}
