//
//  ActionManager+Executor.swift
//  Leanplum
//
//  Created by Milos Jakovljevic on 2.01.22.
//  Copyright © 2023 Leanplum. All rights reserved.

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
                !useAsyncHandlers, // disable dismiss on push open action when using async handlers
                let nextAction = queue.first(),
                nextAction.notification
            {
                let definition = definitions.first { $0.name == action.context.name }
                let _ = definition?.dismissAction?(action.context)
                
                Log.debug("\(ActionManager.logTag): asking for dismissal: \(action.context).")
            }
            return
        }
        
        // gets the next action from the queue
        state.currentAction = queue.pop()
        guard let action = state.currentAction else {
            return
        }
        
        Log.debug("\(ActionManager.logTag): running action with name: \(action.context).")
        
        if action.type == .single,
           Leanplum.shouldSuppressMessage(action.context) {
            Log.info("\(ActionManager.logTag): local IAM caps reached, suppressing \(action.context).")
            state.currentAction = nil
            performAvailableActions()
            return
        }
        
        // decide if we are going to display the message
        // by calling delegate and let it decide what are we supposed to do
        shouldDisplayMessage(context: action.context) { [weak self] messageDisplayDecision in
            // if message is discarded, early exit
            if case .discard = messageDisplayDecision?.decision {
                self?.state.currentAction = nil
                self?.performAvailableActions()
                return
            }
            
            // if message is delayed, add it to the scheduler to be delayed
            // by the amount of seconds, and exit
            if case .delay(let amount) = messageDisplayDecision?.decision {
                Log.debug("\(ActionManager.logTag): delaying action: \(action.context) for \(amount)s.")
                
                if amount > 0 {
                    // Schedule for delayed time
                    self?.scheduler.schedule(action: action, delay: amount)
                } else {
                    // Insert in delayed queue
                    self?.delayedQueue.pushBack(action)
                }
                self?.state.currentAction = nil
                self?.performAvailableActions()
                return
            }
            
            // logic:
            // 1) ask client to show view controller
            // 2) wait for client to execute action
            // 3) ask and wait for client to dismiss view controller
            
            // get the action definition
            let definition = self?.definitions.first { $0.name == action.context.name }
            
            let actionDidExecute: (ActionContext) -> () = { [weak self] context in
                Log.debug("\(ActionManager.logTag): actionDidExecute: \(context).")
                self?.onMessageAction?(context.name, context)
            }
            
            // 2) set the execute block which will be called by client
            action.context.actionDidExecute = { [weak self] context in
                if self?.useAsyncHandlers == true {
                    self?.actionQueue.async {
                        actionDidExecute(context)
                    }
                } else {
                    actionDidExecute(context)
                }
            }
            
            let actionDidDismiss = { [weak self] in
                Log.debug("\(ActionManager.logTag): actionDidDismiss: \(action.context).")
                self?.onMessageDismissed?(action.context)
                self?.state.currentAction = nil
                self?.performAvailableActions()
            }
            
            // 3) set the dismiss block which will be called by client
            action.context.actionDidDismiss = { [weak self] in
                if self?.useAsyncHandlers == true {
                    self?.actionQueue.async {
                        actionDidDismiss()
                    }
                } else {
                    actionDidDismiss()
                }
            }
            
            // 1) ask to present, return if its not
            guard let handled = definition?.presentAction?(action.context), handled else {
                Log.debug("\(ActionManager.logTag): action NOT presented: \(action.context).")
                self?.state.currentAction = nil
                self?.performAvailableActions()
                return
            }
            Log.info("\(ActionManager.logTag): action presented: \(action.context).")
            
            // iff handled track that message has been displayed
            // propagate event that message is displayed
            if self?.useAsyncHandlers == true {
                self?.actionQueue.async { [weak self] in
                    self?.onMessageDisplayed?(action.context)
                }
            } else {
                self?.onMessageDisplayed?(action.context)
            }
            
            // record the impression
            self?.recordImpression(action: action)
        }
    }
    
    func shouldDisplayMessage(context: ActionContext, callback: @escaping (MessageDisplayChoice?) -> ()) {
        if useAsyncHandlers {
            actionQueue.async { [weak self] in
                let messageDisplayDecision = self?.shouldDisplayMessage?(context)
                DispatchQueue.main.async {
                    callback(messageDisplayDecision)
                }
            }
        } else {
            let messageDisplayDecision = self.shouldDisplayMessage?(context)
            callback(messageDisplayDecision)
        }
    }
    
    static var logTag: String {
        "[ActionManager][\(Thread.current.threadName)]"
    }
}
