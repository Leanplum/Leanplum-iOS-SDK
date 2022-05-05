//
//  ActionManagerProcessorTest.swift
//  LeanplumSDKTests
//
//  Created by Nikola Zagorchev on 21.04.22.
//

import XCTest
@testable import Leanplum

class ActionManagerProcessorTest: XCTestCase {
    
    func testMergeValues() {
        let actionManager = ActionManager()
        let resultString = actionManager.merge(vars: "defaultValue", diff: "newValue") as! String
        XCTAssertEqual("newValue", resultString)
        
        let resultNumber = actionManager.merge(vars: 199, diff: 123456789) as! Int
        XCTAssertEqual(123456789, resultNumber)
        
        let resultNull = actionManager.merge(vars: NSNull(), diff: "newValue") as! String
        XCTAssertEqual("newValue", resultNull)
    }
    
//    func testMergeArrays() {
//        let actionManager = ActionManager()
//
//        let arr = [1, 2, 3, 4, 5]
//        let arrDiff = [6, 7, 8, 9, 10]
////        var result = actionManager.merge(vars: arr, diff: arrDiff) as! [AnyHashable]
//        var result = VarCache.shared().mergeHelper(arr, withDiffs: arrDiff) as! [AnyHashable]
//        XCTAssertEqual(arrDiff, result)
//
//        let arrMixed: [AnyHashable] = [1, 2, "value", 4, NSNull()]
//        let arrDiffMixed: [AnyHashable] = [6, 7, "newValue", 9, 10]
////        result = actionManager.merge(vars: arrMixed, diff: arrDiffMixed) as! [AnyHashable]
//        result = VarCache.shared().mergeHelper(arrMixed, withDiffs: arrDiffMixed) as! [AnyHashable]
//        XCTAssertEqual(arrDiffMixed, result)
//    }
        
    func testMergeArraysWithDict() {
        let actionManager = ActionManager()
        
        let arr: [AnyHashable] = [1, 2, 3, 4]
        let arrDiff: [AnyHashable: Any] = ["[0]": 5, "[3]": 6]
        let expected: [AnyHashable] = [5, 2, 3, 6]
        let result = actionManager.merge(vars: arr, diff: arrDiff) as! [AnyHashable]
        XCTAssertEqual(expected, result)
    }
    
    func testMergeArraysMixed() {
        let actionManager = ActionManager()
        
        let arr: [AnyHashable] = [1, 2, "value", 4, NSNull()]
        let arrDiff: [AnyHashable: Any] = ["[0]": 6, "[2]": "newValue", "[4]": "anotherValue"]
        let expected: [AnyHashable] = [6, 2, "newValue", 4, "anotherValue"]
        let result = actionManager.merge(vars: arr, diff: arrDiff) as! [AnyHashable]
        XCTAssertEqual(expected, result)
    }
    
    func testMergeValuesComplex() {
        let messages: [AnyHashable: Any] = [
            "messageId1": [
                "vars": [
                    "myNumber": 0,
                    "myString": "defaultValue"
                ]
            ]
        ]
        
        let messagesDiff: [AnyHashable: Any] = [
            "messageId1": [
                "vars": [
                    "myNumber": 1,
                    "myString": "newValue"
                ]
            ]
        ]
        
        let expected = messagesDiff
        
        let actionManager = ActionManager()
        let result = actionManager.merge(vars: messages, diff: messagesDiff) as! [AnyHashable: Any]
        XCTAssertTrue(result.isEqual(expected))
    }
    
    func testMergeValuesIncludeDefaults() {
        let messages: [AnyHashable: Any] = [
            "messageId1": [
                "vars": [
                    "myNumber": 0,
                    "myString": "defaultValue"
                ]
            ]
        ]
        
        let messagesDiff: [AnyHashable: Any] = [
            "messageId1": [
                "vars": [
                    "myString": "newValue"
                ]
            ]
        ]
        
        let expected: [AnyHashable: Any] = [
            "messageId1": [
                "vars": [
                    "myNumber": 0,
                    "myString": "newValue"
                ]
            ]
        ]
        
        let actionManager = ActionManager()
        let result = actionManager.merge(vars: messages, diff: messagesDiff) as! [AnyHashable: Any]
        XCTAssertTrue(result.isEqual(expected))
    }
    
    func testMergeDictionaries() {
        let dict: [AnyHashable : Any] = [
            "abc": "qwe",
            "nested": [
                "abc": "qwe",
                "1": 123
            ],
            "nested2": [
                "a": "a",
                "b": [1,2,3,4],
                "c": nil,
                "d": 4444
            ]
        ]
        
        let dictDiff: [AnyHashable : Any] = [
            "abc": "rty",
            "nested": [
                "abc": "abc",
                "1": 456
            ],
            "nested2": [
                "a": "a",
                "b": ["[2]": 5, "[3]":  6],
                "c": "value",
                "d": 555
            ]
        ]
        
        let expected: [AnyHashable : Any] = [
            "abc": "rty",
            "nested": [
                "abc": "abc",
                "1": 456
            ],
            "nested2": [
                "a": "a",
                "b": [1,2,5,6],
                "c": "value",
                "d": 555
            ]
        ]
        let actionManager = ActionManager()
        let result = actionManager.merge(vars: dict, diff: dictDiff) as! [AnyHashable: Any]
        XCTAssertTrue(result.isEqual(expected))
    }
    
    func testMergeDictionariesIncludeDefaults() {
        let dict: [AnyHashable : Any] = [
            "abc": "qwe",
            "nested": [
                "abc": "qwe",
                "1": 123
            ],
            "nested2": [
                "a": "a",
                "b": [1,2,3,4],
                "c": nil,
                "d": 4444
            ]
        ]
        
        let dictDiff: [AnyHashable : Any] = [
            "nested": [
                "abc": "abc",
                "qwerty": "qwerty"
            ],
            "nested2": [
                "a": "b",
                "d": 111,
                "e": 999
            ]
        ]
        
        let expected: [AnyHashable : Any] = [
            "abc": "qwe",
            "nested": [
                "abc": "abc",
                "1": 123,
                "qwerty": "qwerty"
            ],
            "nested2": [
                "a": "b",
                "b": [1,2,3,4],
                "c": nil,
                "d": 111,
                "e": 999
            ]
        ]
        let actionManager = ActionManager()
        let result = actionManager.merge(vars: dict, diff: dictDiff) as! [AnyHashable: Any]
        XCTAssertTrue(expected.isEqual(result))
    }
    
    func testMergeDictionariesIncludeDiffs() {
        let dict: [AnyHashable : Any] = [
            "abc": "qwe",
            "nested": [
                "abc": "qwe",
                "1": 123
            ]
        ]
        
        let dictDiff: [AnyHashable : Any] = [
            "nested": [
                "qwerty": "qwerty",
                "nested2": [
                    "a": "b"
                    ]
            ]
        ]
        
        let expected: [AnyHashable : Any] = [
            "abc": "qwe",
            "nested": [
                "abc": "qwe",
                "1": 123,
                "qwerty": "qwerty",
                "nested2": [
                    "a": "b"
                    ]
            ]
        ]
        let actionManager = ActionManager()
        let result = actionManager.merge(vars: dict, diff: dictDiff) as! [AnyHashable: Any]
        XCTAssertTrue(expected.isEqual(result))
    }
}
