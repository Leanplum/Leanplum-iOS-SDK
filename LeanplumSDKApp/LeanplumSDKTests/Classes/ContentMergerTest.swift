//
//  ContentMergerTest.swift
//  LeanplumSDKTests
//
//  Created by Nikola Zagorchev on 21.04.22.
//

import XCTest
@testable import Leanplum

class ContentMergerTest: XCTestCase {
    
    func testMergeValues() {
        let contentMerger = ContentMerger()
        let resultString = contentMerger.merge(vars: "defaultValue", diff: "newValue") as! String
        XCTAssertEqual("newValue", resultString)
        
        let resultNumber = contentMerger.merge(vars: 199, diff: 123456789) as! Int
        XCTAssertEqual(123456789, resultNumber)
        
        let resultNull = contentMerger.merge(vars: NSNull(), diff: "newValue") as! String
        XCTAssertEqual("newValue", resultNull)
    }
    
    func testMergeArrays() {
        let contentMerger = ContentMerger()

        let arr = [1, 2, 3, 4, 5]
        let arrDiff = [6, 7, 8, 9, 10]
        var result = contentMerger.merge(vars: arr, diff: arrDiff) as! [AnyHashable]
        // Merger does not merge two arrays yet, only array with dictionary with indexes, see method implementation for details
        XCTAssertEqual(arr, result)

        let arrMixed: [AnyHashable] = [1, 2, "value", 4, NSNull()]
        let arrDiffMixed: [AnyHashable] = [6, 7, "newValue", 9, 10]
        result = contentMerger.merge(vars: arrMixed, diff: arrDiffMixed) as! [AnyHashable]
        // Merger does not merge two arrays yet, only array with dictionary with indexes, see method implementation for details
        XCTAssertEqual(arrMixed, result)
    }
        
    func testMergeArraysWithDict() {
        let contentMerger = ContentMerger()
        
        let arr: [AnyHashable] = [1, 2, 3, 4]
        let arrDiff: [AnyHashable: Any] = ["[0]": 5, "[3]": 6]
        let expected: [AnyHashable] = [5, 2, 3, 6]
        let result = contentMerger.merge(vars: arr, diff: arrDiff) as! [AnyHashable]
        XCTAssertEqual(expected, result)
    }
    
    func testMergeArraysMixed() {
        let contentMerger = ContentMerger()
        
        let arr: [AnyHashable] = [1, 2, "value", 4, NSNull()]
        let arrDiff: [AnyHashable: Any] = ["[0]": 6, "[2]": "newValue", "[4]": "anotherValue"]
        let expected: [AnyHashable] = [6, 2, "newValue", 4, "anotherValue"]
        let result = contentMerger.merge(vars: arr, diff: arrDiff) as! [AnyHashable]
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
        
        let contentMerger = ContentMerger()
        let result = contentMerger.merge(vars: messages, diff: messagesDiff) as! [AnyHashable: Any]
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
        
        let contentMerger = ContentMerger()
        let result = contentMerger.merge(vars: messages, diff: messagesDiff) as! [AnyHashable: Any]
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
        let contentMerger = ContentMerger()
        let result = contentMerger.merge(vars: dict, diff: dictDiff) as! [AnyHashable: Any]
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
        let contentMerger = ContentMerger()
        let result = contentMerger.merge(vars: dict, diff: dictDiff) as! [AnyHashable: Any]
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
        let contentMerger = ContentMerger()
        let result = contentMerger.merge(vars: dict, diff: dictDiff) as! [AnyHashable: Any]
        XCTAssertTrue(expected.isEqual(result))
    }
    
    func testMergeWithEmpty() {
        let dict: [AnyHashable : Any] = [
            "abc": "qwe",
            "nested": [
                "abc": "qwe",
                "1": 123
            ]
        ]
        
        let dictDiff: [AnyHashable : Any] = [:]
        
        let contentMerger = ContentMerger()
        let result = contentMerger.merge(vars: dict, diff: dictDiff) as! [AnyHashable: Any]
        XCTAssertTrue(dict.isEqual(result))
    }
    
    func testMergeEmpty() {
        let dict: [AnyHashable : Any] = [:]
        
        let dictDiff: [AnyHashable : Any] = [
            "abc": "qwe",
            "nested": [
                "abc": "qwe",
                "1": 123
            ]
        ]
        
        let contentMerger = ContentMerger()
        let result = contentMerger.merge(vars: dict, diff: dictDiff) as! [AnyHashable: Any]
        XCTAssertTrue(dictDiff.isEqual(result))
    }
    
    func testMergeNull() {
        let dict = NSNull()
        
        let dictDiff: [AnyHashable : Any] = [
            "abc": "qwe",
            "nested": [
                "abc": "qwe",
                "1": 123
            ]
        ]
        
        let contentMerger = ContentMerger()
        let result = contentMerger.merge(vars: dict, diff: dictDiff) as! [AnyHashable: Any]
        XCTAssertTrue(dictDiff.isEqual(result))
    }
    
    func testMergeWithNull() {
        let dict: [AnyHashable : Any] = [
            "abc": "qwe",
            "nested": [
                "abc": "qwe",
                "1": 123
            ]
        ]
        
        let dictDiff = NSNull()
        
        let contentMerger = ContentMerger()
        let result = contentMerger.merge(vars: dict, diff: dictDiff)
        XCTAssertTrue(NSNull().isEqual(result))
    }
}
