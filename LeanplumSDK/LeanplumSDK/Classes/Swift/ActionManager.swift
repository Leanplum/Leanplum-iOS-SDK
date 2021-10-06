//
//  ActionManager.swift
//  LeanplumSDK
//
//  Created by Milos Jakovljevic on 20.09.21.
//

import Foundation

public class ActionManager {
    
    public enum ActionTypes {
        case start
        case resume
        case event
        case userAttribute
        case state
    }
    
    public var displayDelegate: MessageDisplayDelegate?
    public var controllerDelegate: MessageControllerDelegate?
    
    lazy var queue: ActionQueue = ActionQueue()
    lazy var scheduler: ActionScheduler = ActionScheduler()
    lazy var state = State()
    lazy var definitions = Definitions()
    
    init() {
        scheduler.delegate = self
    }
    
    public func performAction(types: [ActionTypes], eventName: String) {
        guard let messages = VarCache.shared().messages() else {
            return
        }

        for _ in messages {
            // filter
            // triggers
            // hold back
            // sort
            // execute
            // record impressions
        }
    }
}
