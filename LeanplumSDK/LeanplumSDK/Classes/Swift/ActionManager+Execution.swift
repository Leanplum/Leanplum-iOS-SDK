//
//  ActionManager+Execution.swift
//  LeanplumSDK
//
//  Created by Milos Jakovljevic on 21.09.21.
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
        var state: State
        var context: ActionContext
    }
    
    struct State {
        var currentAction: Action?
    }
    
    func addActions(actions: [Action]) {
        actions.forEach(queue.pushBack(_:))
        execute()
    }
    
    func addActions(actions: [ActionContext]) {
        actions.forEach {
            queue.pushBack(Action(state: .queued, context: $0))
        }
        execute()
    }
    
    func execute() {
        // do not run if we have current action running
        guard state.currentAction == nil else {
            return
        }
        // gets the next action from the queue
        state.currentAction = queue.pop()
        guard var action = state.currentAction else {
            return
        }
        // change state to executing
        action.state = .executing
        
        // reset state when we finish executing current action
        defer {
            state.currentAction = nil
            execute()
        }

        // decide if we are going to display the message
        // by calling delegate and let it decide what are we supposed to do
        let messageDisplayDecision = controllerDelegate?.shouldDisplayMessage(action: action.context) ?? .show
        
        // if message is discarded, early exit
        if case .discard = messageDisplayDecision {
            return
        }
        
        // if message is delayed, add it to the scheduler to be delayed
        // by the amount of seconds, and exit
        if case .delay(let amount) = messageDisplayDecision {
            if amount > 0 {
                scheduler.schedule(action: action, delay: amount)
            } else {
                state.currentAction?.state = .delayed
                addActions(actions: [action])
            }
            return
        }
        
        // logic:
        // 1) ask client to show view controller
        // 2) ask and wait for client to execute action
        // 3) ask and wait for client to dismiss view controller
        
        // get the action definition
        let definition = definitions.actionDefinitions.first { $0.name == action.context.name }
        
        // 3) set the dismiss block
        action.context.dismissBlock = { [weak self] in
            self?.displayDelegate?.onMessageDismissed(action: action.context)
        }

        // 2) set the action block
        action.context.actionBlock = { [weak self] name, tracked in
            tracked ? action.context.runTrackedAction(name: name) : action.context.runAction(name: name)
            self?.displayDelegate?.onMessageClicked(action: action.context)
        }
        
        // 1) ask to present, return if its not
        guard let presented = definition?.present?(action.context), presented else {
            return
        }
        // propagate event that message is displayed
        displayDelegate?.onMessageDisplayed(action: action.context)
    }
}
