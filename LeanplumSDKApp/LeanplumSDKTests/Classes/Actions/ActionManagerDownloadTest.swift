//
//  ActionManagerDownloadTest.swift
//  LeanplumSDKTests
//
//  Created by Nikola Zagorchev on 18.05.22.
//

import XCTest
@testable import Leanplum

class ActionManagerDownloadTest: XCTestCase {
    func testKindFilesDownload() {
        let definitionKinds: [String: String] = [
            "file1": LP_KIND_FILE,
            "file2": LP_KIND_FILE,
        ]

        let defaultArgs: [AnyHashable: Any] = [
            "file1": "file1.jpeg",
            "file2": "file2.jpeg"
        ]

        let args: [AnyHashable: Any] = [
            "file1": "file1-override.jpeg",
            "file2": "file2-override.jpeg"
        ]

        var pairs: [String: String] = [
            "file1-override.jpeg": "file1.jpeg",
            "file2-override.jpeg": "file2.jpeg"
        ]

        let expectation = expectation(description: "testKindFilesDownload")
        let actionManager = ActionManager()
        actionManager.forEachArg(args: args, defaultArgs: defaultArgs, definitionKinds: definitionKinds) { value, defaultValue in
            XCTAssertEqual(pairs[value], defaultValue)
            pairs.removeValue(forKey: value)
            if pairs.isEmpty {
                expectation.fulfill()
            }
        }

        waitForExpectations(timeout: 5.0)
    }
    
    func testKindFilesNestedDownload() {
        let definitionKinds: [String: String] = [
            "file1": LP_KIND_FILE,
            "nested.inner.file2": LP_KIND_FILE
        ]

        let defaultArgs: [AnyHashable: Any] = [
            "file1": "file1.jpeg",
            "nested": [
                "inner": [
                    "file2": "file2.jpeg"
                ]
            ]
        ]

        let args: [AnyHashable: Any] = [
            "file1": "file1-override.jpeg",
            "nested": [
                "inner": [
                    "file2": "file2-override.jpeg"
                ]
            ]
        ]

        var pairs: [String: String] = [
            "file1-override.jpeg": "file1.jpeg",
            "file2-override.jpeg": "file2.jpeg"
        ]

        let expectation = expectation(description: "testKindFilesNestedDownload")
        let actionManager = ActionManager()
        actionManager.forEachArg(args: args, defaultArgs: defaultArgs, definitionKinds: definitionKinds) { value, defaultValue in
            XCTAssertEqual(pairs[value], defaultValue)
            pairs.removeValue(forKey: value)
            if pairs.isEmpty {
                expectation.fulfill()
            }
        }

        waitForExpectations(timeout: 5.0)
    }
    
    func testFilePrefixDownload() {
        let definitionKinds: [String: String] = [:]

        let defaultArgs: [AnyHashable: Any] = [:]

        let args: [AnyHashable: Any] = [
            "__file__1": "file1-override.jpeg",
            "nested": [
                "inner": [
                    "__file__2": "file2-override.jpeg"
                ]
            ]
        ]

        var pairs: [String: String] = [
            "file1-override.jpeg": "",
            "file2-override.jpeg": ""
        ]

        let expectation = expectation(description: "testFilePrefixDownload")
        let actionManager = ActionManager()
        actionManager.forEachArg(args: args, defaultArgs: defaultArgs, definitionKinds: definitionKinds) { value, defaultValue in
            XCTAssertEqual(pairs[value], defaultValue)
            pairs.removeValue(forKey: value)
            if pairs.isEmpty {
                expectation.fulfill()
            }
        }

        waitForExpectations(timeout: 5.0)
    }
    
    func testFileActionDownload() {
        let definitionKinds: [String: String] = [
            "file1": LP_KIND_FILE,
            "action": LP_KIND_ACTION
        ]

        let defaultArgs: [AnyHashable: Any] = [
            "file1": "file1.jpeg",
            "action": ""
        ]

        let args: [AnyHashable: Any] = [
            "file1": "file1-override.jpeg",
            "action": [
                LP_VALUE_ACTION_ARG: "TestDefinition",
                "Image": "file-html-override.jpeg",
                "nested": [
                    "inner": [
                        "__file__2": "file2-override.jpeg"
                    ]
                ]
            ]
        ]

        var pairs: [String: String] = [
            "file1-override.jpeg": "file1.jpeg",
            "file2-override.jpeg": "",
            "file-html-override.jpeg": "",
        ]
        
        let testDefinition = ActionManager.ActionDefinition(name: "TestDefinition",
                                                                            args: [ActionArg(name: "Image", file: "")],
                                                                            kind: .message,
                                                                            options: [:])
        

        let expectation = expectation(description: "testFileActionDownload")
        let actionManager = ActionManager()
        actionManager.defineAction(definition: testDefinition)
        actionManager.forEachArg(args: args, defaultArgs: defaultArgs, definitionKinds: definitionKinds) { value, defaultValue in
            XCTAssertEqual(pairs[value], defaultValue)
            pairs.removeValue(forKey: value)
            if pairs.isEmpty {
                expectation.fulfill()
            }
        }

        waitForExpectations(timeout: 5.0)
    }
}
