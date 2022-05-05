//
//  ActionManager.swift
//  Leanplum
//
//  Created by Milos Jakovljevic on 2.01.22.
//

import Foundation

@objcMembers public class ActionManager: NSObject {
    public static let shared: ActionManager = .init()

    lazy var queue: Queue = Queue()
    lazy var scheduler: Scheduler = Scheduler()
    lazy var state = State()
    
    public var definitions: [ActionDefinition] = []
    public var messages: [AnyHashable:Any] = [:]
    public var messagesDataFromServer: [AnyHashable:Any] = [:] // messageDiffs
    public var devModeActionDefinitionsFromServer: [AnyHashable:Any] = [:]

    public var isEnabled: Bool = true
    public var isPaused: Bool = false {
        didSet {
            if isPaused == false {
                performActions()
            }
        }
    }

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
        guard isEnabled else { return }
        actions.forEach(appendAction(action:))
    }

    /// Adds ActionContext to front of the queue
    func insertActions(actions: [Action]) {
        guard isEnabled else { return }
        actions.forEach(insertAction(action:))
    }
}

extension ActionManager {
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

