//
//  ActionManagerTest.swift
//  LeanplumSDKTests
//
//  Created by Milos Jakovljevic on 11.01.22.
//

import XCTest
@testable import Leanplum

class ActionManagerTest: XCTestCase {

    override func setUpWithError() throws {

    }

    override func tearDownWithError() throws {

    }

    func test_addActions() {
        let actionManager = ActionManager()

        actionManager.addActions(contexts: [
            ActionContext(name: "name", args: [:], messageId: "id_1"),
            ActionContext(name: "name", args: [:], messageId: "id_2")
        ])
        XCTAssertTrue(!actionManager.queue.empty())
        XCTAssertEqual(actionManager.queue.count(), 2)
    }

    func test_appendActions() {
        let actionManager = ActionManager()

        actionManager.addActions(contexts: [
            ActionContext(name: "name_1", args: [:], messageId: "id_1"),
            ActionContext(name: "name_2", args: [:], messageId: "id_2")
        ])

        actionManager.appendActions(contexts: [
            ActionContext(name: "name_3", args: [:], messageId: "id_3")
        ])

        XCTAssertTrue(!actionManager.queue.empty())
        XCTAssertEqual(actionManager.queue.last()?.context.messageId, "id_3")
        XCTAssertEqual(actionManager.queue.count(), 3)
    }

    func test_insertActions() {
        let actionManager = ActionManager()

        actionManager.addActions(contexts: [
            ActionContext(name: "name_1", args: [:], messageId: "id_1"),
            ActionContext(name: "name_2", args: [:], messageId: "id_2")
        ])

        actionManager.insertActions(contexts: [
            ActionContext(name: "name_3", args: [:], messageId: "id_3")
        ])

        XCTAssertTrue(!actionManager.queue.empty())
        XCTAssertEqual(actionManager.queue.first()?.context.messageId, "id_3")
        XCTAssertEqual(actionManager.queue.count(), 3)
    }

    func test_enabledActionManager() {
        let actionManager = ActionManager()
        actionManager.enabled = true

        let context = ActionContext(name: "name", args: [:], messageId: "id")

        actionManager.addActions(contexts: [context])
        XCTAssertTrue(!actionManager.queue.empty())
    }

    func test_disabledActionManager() {
        let actionManager = ActionManager()
        actionManager.enabled = false

        let context = ActionContext(name: "name", args: [:], messageId: "id")

        actionManager.addActions(contexts: [context])
        XCTAssertTrue(actionManager.queue.empty())
    }
}
