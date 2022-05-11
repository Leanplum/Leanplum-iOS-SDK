//
//  ActionManager.swift
//  Leanplum
//
//  Created by Milos Jakovljevic on 2.01.22.
//

import Foundation

@objcMembers public class ActionManager: NSObject {
    public static let shared: ActionManager = .init()

    public var configuration: Configuration = .default

    lazy var queue: Queue = Queue()
    lazy var delayedQueue: Queue = Queue()
    lazy var scheduler: Scheduler = Scheduler()
    lazy var state = State()
    
    public var definitions: [ActionDefinition] = []
    public var messages: [AnyHashable: Any] = [:]
    /// Raw messages data received from the API
    public var messagesDataFromServer: [AnyHashable: Any] = [:]
    public var actionDefinitionsFromServer: [AnyHashable: Any] = [:]

    public var isEnabled: Bool = true {
        didSet {
            Log.info("[ActionManager] isEnabled: \(isEnabled)")
        }
    }
    public var isPaused: Bool = false {
        didSet {
            if isPaused == false {
                performAvailableActions()
            }
            Log.info("[ActionManager] isPaused: \(isPaused)")
        }
    }

    override init() {
        super.init()
        queue.didChange = {
            self.performAvailableActions()
        }
        scheduler.actionDelayed = {
            self.appendActions(actions: [$0])
        }
        
        NotificationCenter
            .default
            .addObserver(forName: UIApplication.didBecomeActiveNotification,
                         object: self,
                         queue: .main) { [weak self] _ in
                guard let `self` = self else { return }
                if self.configuration.resumeOnEnterForeground {
                    self.performAvailableActions()
                }
            }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    var shouldDisplayMessage: ((ActionContext) -> MessageDisplayChoice)?
    @objc public func shouldDisplayMessage(_ callback: @escaping (ActionContext) -> MessageDisplayChoice) {
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
    
    func performAvailableActions() {
        Log.debug("[ActionManager]: performing all available actions.")
        Leanplum.onceVariablesChangedAndNoDownloadsPending {
            self.performActions()
        }
    }
}

extension ActionManager {
    /// Adds action to back of the queue
    func appendActions(actions: [Action]) {
        guard isEnabled else { return }
        actions.forEach(queue.pushBack(_:))
    }

    /// Adds action to front of the queue
    func insertActions(actions: [Action]) {
        guard isEnabled else { return }
        actions
            .reversed()
            .forEach(queue.pushFront(_:))
    }
}
