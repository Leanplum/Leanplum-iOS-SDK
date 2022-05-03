//
//  ActionManager+Executor.swift
//  Leanplum
//
//  Created by Milos Jakovljevic on 2.01.22.
//

import Foundation

extension ActionManager {
    @objc public func performActions() {
        // If we are paused, exit as we will continue execution
        // when we are resumed.
        guard isPaused == false else {
            return
        }
        // ask user to dimiss current action so we can execute next one
        if
            let action = state.currentAction,
            let nextAction = queue.first(),
            nextAction.notification
        {
            let definition = definitions.first { $0.name == action.context.name }
            let _ = definition?.dismissAction?(action.context)
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
        if case .delay(let amount) = messageDisplayDecision?.decision, amount > 0 {
            action.state = .delayed
            scheduler.schedule(action: action, delay: amount)
            state.currentAction = nil
            performActions()
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
            self?.onMessageAction?(context.name, context)
        }

        // 3) set the dismiss block which will be called by client
        action.context.actionDidDismiss = { [weak self] in
            self?.onMessageDismissed?(action.context)
            self?.state.currentAction = nil
            self?.performActions()
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

        // record the impression
        recordImpression(action: action)
    }
}
