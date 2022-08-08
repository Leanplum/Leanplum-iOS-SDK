//
//  ActionManager+Executor.swift
//  Leanplum
//
//  Created by Milos Jakovljevic on 2.01.22.
//  Copyright © 2022 Leanplum. All rights reserved.

import Foundation

extension ActionManager {
    func performActions() {
        // If we are paused or disabled, exit as we will continue execution
        // when we are resumed.
        guard !isPaused, isEnabled else {
            return
        }
        
        if let action = state.currentAction {
            // ask user to dimiss current action so we can execute next one
            if
                configuration.dismissOnPushArrival,
                let nextAction = queue.first(),
                nextAction.notification
            {
                let definition = definitions.first { $0.name == action.context.name }
                let _ = definition?.dismissAction?(action.context)
                
                Log.debug("[ActionManager]: asking for dismissal: \(action.context).")
            }
            return
        }

        // gets the next action from the queue
        state.currentAction = queue.pop()
        guard let action = state.currentAction else {
            return
        }
        
        Log.debug("[ActionManager]: running action with name: \(action.context).")
        
        if action.type == .single,
           Leanplum.shouldSuppressMessage(action.context) {
            Log.info("[ActionManager]: local IAM caps reached, suppressing \(action.context).")
            state.currentAction = nil
            performAvailableActions()
            return
        }

        // decide if we are going to display the message
        // by calling delegate and let it decide what are we supposed to do
        let messageDisplayDecision = shouldDisplayMessage?(action.context)

        // if message is discarded, early exit
        if case .discard = messageDisplayDecision?.decision {
            state.currentAction = nil
            performAvailableActions()
            return
        }

        // if message is delayed, add it to the scheduler to be delayed
        // by the amount of seconds, and exit
        if case .delay(let amount) = messageDisplayDecision?.decision {
            Log.debug("[ActionManager]: delaying action: \(action.context) for \(amount)s.")

            if amount > 0 {
                // Schedule for delayed time
                scheduler.schedule(action: action, delay: amount)
            } else {
                // Insert in delayed queue
                delayedQueue.pushBack(action)
            }
            state.currentAction = nil
            performAvailableActions()
            return
        }

        // logic:
        // 1) ask client to show view controller
        // 2) wait for client to execute action
        // 3) ask and wait for client to dismiss view controller

        // get the action definition
        let definition = definitions.first { $0.name == action.context.name }

        // 2) set the execute block which will be called by client
        action.context.actionDidExecute = { [weak self] context in
            Log.debug("[ActionManager]: actionDidExecute: \(context).")
            self?.onMessageAction?(context.name, context)
        }

        // 3) set the dismiss block which will be called by client
        action.context.actionDidDismiss = { [weak self] in
            Log.debug("[ActionManager]: actionDidDismiss: \(action.context).")
            self?.onMessageDismissed?(action.context)
            self?.state.currentAction = nil
            self?.performAvailableActions()
        }

        // 1) ask to present, return if its not
        guard let handled = definition?.presentAction?(action.context), handled else {
            Log.debug("[ActionManager]: action NOT presented: \(action.context).")
            state.currentAction = nil
            performAvailableActions()
            return
        }
        Log.info("[ActionManager]: action presented: \(action.context).")

        // iff handled track that message has been displayed
        // propagate event that message is displayed
        onMessageDisplayed?(action.context)

        // record the impression
        recordImpression(action: action)
    }
}
