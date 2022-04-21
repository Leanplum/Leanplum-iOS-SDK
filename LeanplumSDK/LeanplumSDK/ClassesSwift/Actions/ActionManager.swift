//
//  ActionManager.swift
//  Leanplum
//
//  Created by Milos Jakovljevic on 2.01.22.
//

import Foundation

@objc public class ActionManager: NSObject {
    @objc public static let shared: ActionManager = .init()
    
    lazy var queue: Queue = Queue()
    lazy var scheduler: Scheduler = Scheduler()
    lazy var state = State()
    
    @objc public var definitions: [ActionDefinition] = []
    @objc public var messages: [AnyHashable:Any] = [:]
    @objc public var messagesDataFromServer: [AnyHashable:Any] = [:] // messageDiffs
    @objc public var devModeActionDefinitionsFromServer: [AnyHashable:Any] = [:]

    public var enabled: Bool = true

    override init() {
        super.init()
        queue.didChange = {
            self.performActions()
        }
        scheduler.actionDelayed = {
            self.appendActions(actions: [$0])
        }
    }

    var shouldDisplayMessage: ((ActionContext) -> MessageOrder)?
    @objc public func shouldDisplayMessage(_ callback: @escaping (ActionContext) -> MessageOrder) {
        shouldDisplayMessage = callback
    }

    var onMessageDisplayed: ((ActionContext) -> Void)?
    @objc public func onMessageDisplayed(_ callback: @escaping (ActionContext) -> Void) {
        onMessageDisplayed = callback
    }

    var onMessageDismissed: ((ActionContext) -> Void)?
    @objc public func onMessageDismissed(_ callback: @escaping (ActionContext) -> Void) {
        onMessageDismissed = callback
    }

    var onMessageAction: ((_ actionName: String, _ context: ActionContext) -> Void)?
    @objc public func onMessageAction(_ callback: @escaping (_ actionName: String, _ context: ActionContext) -> Void) {
        onMessageAction = callback
    }

    var orderMessages: ((_ contexts: [ActionContext], _ trigger: ActionsTrigger?) -> [ActionContext])?
    @objc public func orderMessages(_ callback:  @escaping (_ contexts: [ActionContext], _ trigger: ActionsTrigger?) -> [ActionContext]) {
        orderMessages = callback
    }
}

extension ActionManager {
    /// Adds ActionContext to back of the queue
    func appendActions(actions: [Action]) {
        guard enabled else { return }
        actions.forEach(appendAction(action:))
    }

    /// Adds ActionContext to front of the queue
    func insertActions(actions: [Action]) {
        guard enabled else { return }
        actions.forEach(insertAction(action:))
    }
}

extension ActionManager {
    /// Adds action to front or back of the queue depending on action type
    func addActions(actions: [Action]) {
        guard enabled else { return }
        actions.forEach { action in
            if action.type == .chained {
                insertAction(action: action)
            } else {
                appendAction(action: action)
            }
        }
    }

    /// Adds action to back of the queue
    func appendAction(action: Action) {
        if action.context.hasMissingFiles() {
            Leanplum.onceVariablesChangedAndNoDownloadsPending {
                self.queue.pushBack(action)
            }
        } else {
            queue.pushBack(action)
        }
    }

    /// Adds action to front of the queue
    func insertAction(action: Action) {
        if action.context.hasMissingFiles() {
            Leanplum.onceVariablesChangedAndNoDownloadsPending {
                self.queue.pushFront(action)
            }
        } else {
            queue.pushFront(action)
        }
    }
}

