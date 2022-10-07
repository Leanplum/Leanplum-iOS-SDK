//
//  ActionManager.swift
//  Leanplum
//
//  Created by Milos Jakovljevic on 2.01.22.
//  Copyright © 2022 Leanplum. All rights reserved.

import Foundation

@objc(LPActionManager)
@objcMembers public class ActionManager: NSObject {
    public static let shared: ActionManager = .init()

    /// `ActionManager.Configuration` of the `ActionManager`
    /// Set a new configuration to override a configuration option
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

    /// When disabled, it stops executing actions and new actions will not be added to the queue.
    public var isEnabled: Bool = true {
        didSet {
            if isEnabled && !oldValue {
                performAvailableActions()
            }
            Log.info("[ActionManager] isEnabled: \(isEnabled)")
        }
    }
    
    /// When paused, it stops executing actions but new actions will continue to be added to the queue
    /// Value will be changed to `false` when app is in background and to `true` when app enters foreground
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
        scheduler.actionDelayed = {
            self.appendActions(actions: [$0])
        }
        
        NotificationCenter
            .default
            .addObserver(forName: UIApplication.didBecomeActiveNotification,
                         object: nil,
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
    /// Called per message to decide whether to show, discard or delay it.
    /// - Note: to delay a message indefinitely, use delay with value -1
    @objc public func shouldDisplayMessage(_ callback: ((ActionContext) -> MessageDisplayChoice)?) {
        shouldDisplayMessage = callback
    }

    var onMessageDisplayed: ((ActionContext) -> Void)?
    /// Called when the message is displayed.
    @objc public func onMessageDisplayed(_ callback: ((ActionContext) -> Void)?) {
        onMessageDisplayed = callback
    }

    var onMessageDismissed: ((ActionContext) -> Void)?
    /// Called when the message is dismissed.
    @objc public func onMessageDismissed(_ callback: ((ActionContext) -> Void)?) {
        onMessageDismissed = callback
    }

    var onMessageAction: ((_ actionName: String, _ context: ActionContext) -> Void)?
    /// Called when a message action is executed.
    @objc public func onMessageAction(_ callback: ((_ actionName: String, _ context: ActionContext) -> Void)?) {
        onMessageAction = callback
    }

    var prioritizeMessages: ((_ contexts: [ActionContext], _ trigger: ActionsTrigger?) -> [ActionContext])?
    /// Called when there are multiple messages to be displayed. Messages are ordered by Priority.
    /// Messages can be reordered or removed if desired. Removed messages will not be presented.
    /// Messages will be presented one after another in the order returned.
    ///
    /// - Note: If this function is not implemented, the first message is presented only.
    ///
    /// - Parameters:
    ///     - callback: contexts - messages' contexts and trigger - the action trigger that triggered the messages
    ///
    /// - Returns: the messages that should be presented in that order
    @objc public func prioritizeMessages(_ callback: ((_ contexts: [ActionContext], _ trigger: ActionsTrigger?) -> [ActionContext])?) {
        prioritizeMessages = callback
    }
    
    func performAvailableActions() {
        Log.debug("[ActionManager]: performing all available actions.")
        Leanplum.onceVariablesChangedAndNoDownloadsPending {
            DispatchQueue.main.async {
                self.performActions()
            }
        }
    }
}

extension ActionManager {
    /// Adds action to back of the queue
    func appendActions(actions: [Action]) {
        guard isEnabled else { return }
        actions.forEach(queue.pushBack(_:))
        performAvailableActions()
    }

    /// Adds action to front of the queue
    func insertActions(actions: [Action]) {
        guard isEnabled else { return }
        actions
            .reversed()
            .forEach(queue.pushFront(_:))
        performAvailableActions()
    }
}
