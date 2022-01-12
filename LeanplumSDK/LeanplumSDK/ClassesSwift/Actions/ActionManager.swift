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
    lazy var definitions: [ActionDefinition] = []

    private override init() {
        super.init()
        scheduler.delegate = self
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

    var sortAndOrderMessages: ((_ contexts: [ActionContext], _ trigger: ActionsTrigger?) -> [ActionContext])?
    @objc public func sortAndOrderMessages(_ callback:  @escaping (_ contexts: [ActionContext], _ trigger: ActionsTrigger?) -> [ActionContext]) {
        sortAndOrderMessages = callback
    }
}

extension ActionManager {
    /// Adds ActionContext to front or back of the queue depending on action type
    @objc public func addActions(contexts: [ActionContext]) {
        let actions: [Action] = contexts.map {
            .action(context: $0)
        }
        addActions(actions: actions)
    }

    /// Adds ActionContext to back of the queue
    @objc public func appendActions(contexts: [ActionContext]) {
        let actions: [Action] = contexts.map {
            .action(context: $0)
        }
        appendActions(actions: actions)
    }

    /// Adds ActionContext to front of the queue
    @objc public func insertActions(contexts: [ActionContext]) {
        let actions: [Action] = contexts.map {
            .action(context: $0)
        }
        insertActions(actions: actions)
    }
}

extension ActionManager {
    /// Adds action to front or back of the queue depending on action type
    func addActions(actions: [Action]) {
        actions.forEach { action in
            if action.type == .chained {
                insertActions(actions: actions)
            } else {
                appendActions(actions: actions)
            }
        }
    }

    /// Adds action to back of the queue
    func appendActions(actions: [Action]) {
        actions.forEach { action in
            if action.context.hasMissingFiles() {
                Leanplum.onceVariablesChangedAndNoDownloadsPending {
                    self.queue.pushBack(action)
                }
            }
        }
    }

    /// Adds action to front of the queue
    func insertActions(actions: [Action]) {
        actions.forEach { action in
            if action.context.hasMissingFiles() {
                Leanplum.onceVariablesChangedAndNoDownloadsPending {
                    self.queue.pushFront(action)
                }
            }
        }
    }
}

