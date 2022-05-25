//
//  ActionManagerTest.swift
//  LeanplumSDKTests
//
//  Created by Milos Jakovljevic on 11.01.22.
//  Copyright © 2022 Leanplum. All rights reserved.

import XCTest
@testable import Leanplum

class ActionManagerTest: XCTestCase {

    override func setUpWithError() throws {

    }

    override func tearDownWithError() throws {

    }

    func testAddActions() {
        let actionManager = ActionManager()

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
        
        actionManager.orderMessages { contexts, trigger in
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
        
        actionManager.orderMessages { contexts, trigger in
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
        // message should be readded
        XCTAssertEqual(actionManager.queue.count(), 1)
    }
}
