//
//  ActionManagerTest.swift
//  LeanplumSDKTests
//
//  Created by Milos Jakovljevic on 11.01.22.
//  Copyright © 2022 Leanplum. All rights reserved.

import XCTest
@testable import Leanplum

class ActionManagerTest: XCTestCase {

    let hasReceivedDiffs = VarCache.shared().hasReceivedDiffs()
    
    override func setUpWithError() throws {
        // Set actions as available, see `performAvailableActions` for details
        VarCache.shared().setHasReceivedDiffs(true)
    }

    override func tearDownWithError() throws {
        VarCache.shared().setHasReceivedDiffs(hasReceivedDiffs)
    }
    
    func testAddActions() {
        let actionManager = ActionManager()
        actionManager.trigger(contexts: [
            ActionContext(name: "name", args: [:], messageId: "id_1"),
            ActionContext(name: "name", args: [:], messageId: "id_2")
        ])
        XCTAssertTrue(!actionManager.queue.empty())
        XCTAssertEqual(actionManager.queue.count(), 1)
    }
    
    func testAddActionsWithOrder() {
        let actionManager = ActionManager()
        actionManager.prioritizeMessages { contexts, trigger in
            return contexts
        }

        actionManager.trigger(contexts: [
            ActionContext(name: "name", args: [:], messageId: "id_1"),
            ActionContext(name: "name", args: [:], messageId: "id_2")
        ])
        XCTAssertTrue(!actionManager.queue.empty())
        XCTAssertEqual(actionManager.queue.count(), 2)
    }

    func testAppendActions() {
        let actionManager = ActionManager()

        actionManager.trigger(contexts: [
            ActionContext(name: "name_1", args: [:], messageId: "id_1"),
            ActionContext(name: "name_2", args: [:], messageId: "id_2")
        ])
        
        actionManager.trigger(contexts: [
            ActionContext(name: "name_3", args: [:], messageId: "id_3")
        ], priority: .default)
        
        XCTAssertTrue(!actionManager.queue.empty())
        XCTAssertEqual(actionManager.queue.last()?.context.messageId, "id_3")
        XCTAssertEqual(actionManager.queue.count(), 2)
    }
    
    func testAppendActionsWithOrder() {
        let actionManager = ActionManager()
        actionManager.prioritizeMessages { contexts, trigger in
            return contexts
        }
        
        actionManager.trigger(contexts: [
            ActionContext(name: "name_1", args: [:], messageId: "id_1"),
            ActionContext(name: "name_2", args: [:], messageId: "id_2")
        ])
        
        actionManager.trigger(contexts: [
            ActionContext(name: "name_3", args: [:], messageId: "id_3")
        ], priority: .default)
        
        XCTAssertTrue(!actionManager.queue.empty())
        XCTAssertEqual(actionManager.queue.last()?.context.messageId, "id_3")
        XCTAssertEqual(actionManager.queue.count(), 3)
    }
    
    func testInsertActions() {
        let actionManager = ActionManager()
        actionManager.trigger(contexts: [
            ActionContext(name: "name_1", args: [:], messageId: "id_1"),
            ActionContext(name: "name_2", args: [:], messageId: "id_2")
        ])
        
        actionManager.trigger(contexts: [
            ActionContext(name: "name_3", args: [:], messageId: "id_3")
        ], priority: .high)

        XCTAssertTrue(!actionManager.queue.empty())
        XCTAssertEqual(actionManager.queue.first()?.context.messageId, "id_3")
        XCTAssertEqual(actionManager.queue.last()?.context.messageId, "id_1")
        XCTAssertEqual(actionManager.queue.count(), 2)
    }
    
    func testInsertActionsWithOrder() {
        let actionManager = ActionManager()
        actionManager.prioritizeMessages { contexts, trigger in
            return contexts
        }
        
        actionManager.trigger(contexts: [
            ActionContext(name: "name_1", args: [:], messageId: "id_1"),
            ActionContext(name: "name_2", args: [:], messageId: "id_2")
        ])
        
        actionManager.trigger(contexts: [
            ActionContext(name: "name_3", args: [:], messageId: "id_3")
        ], priority: .high)

        XCTAssertTrue(!actionManager.queue.empty())
        XCTAssertEqual(actionManager.queue.first()?.context.messageId, "id_3")
        XCTAssertEqual(actionManager.queue.count(), 3)
    }

    func testEnabledActionManager() {
        let actionManager = ActionManager()
        actionManager.isEnabled = true

        let context = ActionContext(name: "name", args: [:], messageId: "id")

        actionManager.trigger(contexts: [context])
        XCTAssertTrue(!actionManager.queue.empty())
    }

    func testDisabledActionManager() {
        let actionManager = ActionManager()
        actionManager.isEnabled = false

        let context = ActionContext(name: "name", args: [:], messageId: "id")

        actionManager.trigger(contexts: [context])
        XCTAssertTrue(actionManager.queue.empty())
    }
    
    func testOrderMessages() {
        let actionManager = ActionManager()
        
        let testContexts: [ActionContext] = [
            .init(name: "first", args: [:], messageId: "first"),
            .init(name: "second", args: [:], messageId: "second"),
            .init(name: "third", args: [:], messageId: "third"),
        ]
        
        actionManager.prioritizeMessages { contexts, trigger in
            XCTAssertEqual(contexts.count, testContexts.count)
            return contexts
        }
        
        actionManager.trigger(contexts: testContexts)
        
        XCTAssertEqual(actionManager.queue.count(), testContexts.count)
    }
    
    func testOrderMessagesWithReordering() {
        let actionManager = ActionManager()
        
        let testContexts: [ActionContext] = [
            .init(name: "first", args: [:], messageId: "first"),
            .init(name: "second", args: [:], messageId: "second"),
            .init(name: "third", args: [:], messageId: "third"),
        ]
        
        actionManager.prioritizeMessages { contexts, trigger in
            XCTAssertEqual(contexts.count, testContexts.count)
            var ordered = contexts
            ordered.swapAt(0, 2)
            return ordered
        }
        
        actionManager.trigger(contexts: testContexts)
        
        XCTAssertEqual(actionManager.queue.count(), testContexts.count)
        XCTAssertEqual(actionManager.queue.first()?.context.messageId, testContexts.last?.messageId)
    }
    
    func testPresentMessage() {
        let expectation = expectation(description: #function)
        let testContext: ActionContext = .init(name: #function, args: [:], messageId: #function)

        let actionManager = ActionManager()
        actionManager.defineAction(definition:
                .message(name: #function,
                         args: [],
                         options: [:],
                         presentAction: { context in
            XCTAssertEqual(context.messageId, testContext.messageId)
            expectation.fulfill()
            return true
        }))
    
        actionManager.shouldDisplayMessage { context in
            return .show()
        }
        
        actionManager.trigger(contexts: [testContext])
        XCTAssertEqual(actionManager.queue.count(), 1)
        
        waitForExpectations(timeout: 2.0)
    }
    
    func testShouldDisplayShowMessage() {
        let actionManager = ActionManager()
        actionManager.defineAction(definition:
                .message(name: #function,
                         args: [],
                         options: [:],
                         presentAction: { context in
            return true
        }))
        
        let testContext: ActionContext = .init(name: #function, args: [:], messageId: #function)

        actionManager.shouldDisplayMessage { context in
            return .show()
        }
        
        let expectation = expectation(description: #function)
        actionManager.onMessageDisplayed { context in
            XCTAssertEqual(context.messageId, testContext.messageId)
            expectation.fulfill()
        }
        
        actionManager.trigger(contexts: [testContext])
        XCTAssertEqual(actionManager.queue.count(), 1)
        
        waitForExpectations(timeout: 2.0)
    }
    
    func testShouldDisplayDiscardMessage() {
        let actionManager = ActionManager()
        actionManager.defineAction(definition:
                .message(name: #function,
                         args: [],
                         options: [:],
                         presentAction: { context in
            return true
        }))
        
        let testContext: ActionContext = .init(name: #function, args: [:], messageId: #function)

        actionManager.shouldDisplayMessage { context in
            return .discard()
        }
        
        let expectation = expectation(description: #function)
        expectation.isInverted = true
        actionManager.onMessageDisplayed { context in
            XCTAssertEqual(context.messageId, testContext.messageId)
            expectation.fulfill()
        }
        
        actionManager.trigger(contexts: [testContext])
        XCTAssertEqual(actionManager.queue.count(), 1)
        waitForExpectations(timeout: 2.0)
    }
    
    func testShouldDisplayDelayMessage() {
        let actionManager = ActionManager()
        
        actionManager.defineAction(definition:
                .message(name: #function,
                         args: [],
                         options: [:],
                         presentAction: { context in
            return true
        }))
        
        let testContext: ActionContext = .init(name: #function, args: [:], messageId: #function)
        actionManager.shouldDisplayMessage { context in
                return .delay(seconds: 1)
        }
        
        let expectation = expectation(description: #function)
        expectation.isInverted = true
        actionManager.onMessageDisplayed { context in
            XCTAssertEqual(context.messageId, testContext.messageId)
            expectation.fulfill()
        }
        
        actionManager.trigger(contexts: [testContext])
        XCTAssertEqual(actionManager.queue.count(), 1)
        waitForExpectations(timeout: 3.0)
    }
    
    func testShouldDisplayActionDelayed() {
        let actionManager = ActionManager()
        
        let testContext: ActionContext = .init(name: #function, args: [:], messageId: #function)
        
        let expectation = expectation(description: #function)
        let scheduler = ActionManager.Scheduler()
        scheduler.actionDelayed = { action in
            XCTAssertEqual(action.context.messageId, testContext.messageId)
            expectation.fulfill()
        }
        
        actionManager.scheduler = scheduler
        
        actionManager.defineAction(definition:
                .message(name: #function,
                         args: [],
                         options: [:],
                         presentAction: { context in
            return true
        }))
        
        actionManager.shouldDisplayMessage { context in
            return .delay(seconds: 1)
        }
        
        actionManager.trigger(contexts: [testContext])
        waitForExpectations(timeout: 3.0)
    }
    
    func testShouldDisplayDelayIndefinitely() {
        let actionManager = ActionManager()
        
        actionManager.defineAction(definition:
                .message(name: #function,
                         args: [],
                         options: [:],
                         presentAction: { context in
            return true
        }))
        
        let testContext: ActionContext = .init(name: #function, args: [:], messageId: #function)
        actionManager.shouldDisplayMessage { context in
            return .delay(seconds: -1)
        }
        
        let expectation = expectation(description: #function)
        expectation.isInverted = true
        
        actionManager.onMessageDisplayed { context in
            XCTAssertEqual(context.messageId, testContext.messageId)
            expectation.fulfill()
        }
        
        actionManager.trigger(contexts: [testContext])
        waitForExpectations(timeout: 3.0)
        XCTAssertEqual(actionManager.delayedQueue.count(), 1)
    }
    
    func testTriggerDelayedMessages() {
        let actionManager = ActionManager()
        actionManager.defineAction(definition:
                .message(name: #function,
                         args: [],
                         options: [:],
                         presentAction: { context in
            return true
        }))
        
        let testContext: ActionContext = .init(name: #function, args: [:], messageId: #function)
        
        let expectation = expectation(description: #function)
        actionManager.onMessageDisplayed { context in
            XCTAssertEqual(context.messageId, testContext.messageId)
            expectation.fulfill()
        }
        
        // Delay the message until triggered
        actionManager.shouldDisplayMessage { context in
            return .delay(seconds: -1)
        }
        
        actionManager.trigger(contexts: [testContext])
        
        // Wait for performActions so message is actually delayed first
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            
            // Display the message now
            actionManager.shouldDisplayMessage { context in
                return .show()
            }
            
            // Ensure the message is in the delayedQueue
            XCTAssertEqual(actionManager.delayedQueue.count(), 1)
            actionManager.triggerDelayedMessages()
        }
        
        waitForExpectations(timeout: 3.0)
        XCTAssertEqual(actionManager.delayedQueue.count(), 0)
    }
    
    func testActionExecuted() {
        let actionManager = ActionManager()
        actionManager.defineAction(definition:
                .message(name: #function,
                         args: [],
                         options: [:],
                         presentAction: { context in
            return true
        }))
        
        let testContext: ActionContext = .init(name: #function, args: [:], messageId: #function)
        
        let expectation = expectation(description: #function)
        actionManager.onMessageAction { actionName, context in
            XCTAssertEqual(actionName, #function)
            XCTAssertEqual(context.parent?.messageId, testContext.messageId)
            expectation.fulfill()
        }

        actionManager.onMessageDisplayed { context in
            context.runAction(name: #function)
        }
        actionManager.trigger(contexts: [testContext])
        
        waitForExpectations(timeout: 3.0)
    }
}
