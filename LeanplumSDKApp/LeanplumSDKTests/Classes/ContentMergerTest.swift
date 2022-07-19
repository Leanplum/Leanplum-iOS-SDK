//
//  ContentMergerTest.swift
//  LeanplumSDKTests
//
//  Created by Nikola Zagorchev on 21.04.22.
//  Copyright © 2022 Leanplum. All rights reserved.

import XCTest
@testable import Leanplum

class ContentMergerTest: XCTestCase {
    typealias AnyDictionary = [AnyHashable: Any]

    func testMergeValues() {
        let resultString = ContentMerger.merge(vars: "defaultValue", diff: "newValue") as! String
        XCTAssertEqual("newValue", resultString)
        
        let resultNumber = ContentMerger.merge(vars: 199, diff: 123456789) as! Int
        XCTAssertEqual(123456789, resultNumber)
        
        let resultNull = ContentMerger.merge(vars: NSNull(), diff: "newValue") as! String
        XCTAssertEqual("newValue", resultNull)
    }
    
    func testMergeArrays() {
        let arr = [1, 2, 3, 4, 5]
        let arrDiff = [6, 7, 8, 9, 10]
        var result = ContentMerger.merge(vars: arr, diff: arrDiff) as! [AnyHashable]
        // Merger does not merge two arrays yet, only array with dictionary with indexes, see method implementation for details
        XCTAssertEqual(arr, result)

        let arrMixed: [AnyHashable] = [1, 2, "value", 4, NSNull()]
        let arrDiffMixed: [AnyHashable] = [6, 7, "newValue", 9, 10]
        result = ContentMerger.merge(vars: arrMixed, diff: arrDiffMixed) as! [AnyHashable]
        // Merger does not merge two arrays yet, only array with dictionary with indexes, see method implementation for details
        XCTAssertEqual(arrMixed, result)
    }
        
    func testMergeArrayWithDict() {
        let arr: [AnyHashable] = [1, 2, 3, 4]
        let arrDiff: AnyDictionary = ["[0]": 5, "[3]": 6]
        let expected: [AnyHashable] = [5, 2, 3, 6]
        let result = ContentMerger.merge(vars: arr, diff: arrDiff) as! [AnyHashable]
        XCTAssertEqual(expected, result)
    }
    
    func testMergeArrayWithDictAdditionalValue() {
        let arr: [AnyHashable] = [1, 2, 3, 4]
        let arrDiff: AnyDictionary = ["[4]": 5]
        let expected: [AnyHashable] = [1, 2, 3, 4, 5]
        let result = ContentMerger.merge(vars: arr, diff: arrDiff) as! [AnyHashable]
        XCTAssertEqual(expected, result)
    }
    
    func testMergeEmptyArrayWithDict() {
        let arr: [AnyHashable] = []
        let arrDiff: AnyDictionary = ["[4]": 5]
        let expected: [AnyHashable] = [NSNull(), NSNull(), NSNull(), NSNull(), 5]
        let result = ContentMerger.merge(vars: arr, diff: arrDiff) as! [AnyHashable]
        XCTAssertEqual(expected, result)
    }
    
    func testMergeArraysMixed() {
        let arr: [AnyHashable] = [1, 2, "value", 4, NSNull()]
        let arrDiff: AnyDictionary = ["[0]": 6, "[2]": "newValue", "[4]": "anotherValue"]
        let expected: [AnyHashable] = [6, 2, "newValue", 4, "anotherValue"]
        let result = ContentMerger.merge(vars: arr, diff: arrDiff) as! [AnyHashable]
        XCTAssertEqual(expected, result)
    }
    
    func testMergeValuesComplex() {
        let messages: AnyDictionary = [
            "messageId1": [
                "vars": [
                    "myNumber": 0,
                    "myString": "defaultValue"
                ]
            ]
        ]
        
        let messagesDiff: AnyDictionary = [
            "messageId1": [
                "vars": [
                    "myNumber": 1,
                    "myString": "newValue"
                ]
            ]
        ]
        
        let expected = messagesDiff
        
        let result = ContentMerger.merge(vars: messages, diff: messagesDiff) as! AnyDictionary
        XCTAssertTrue(result.isEqual(expected))
    }
    
    func testMergeValuesIncludeDefaults() {
        let messages: AnyDictionary = [
            "messageId1": [
                "vars": [
                    "myNumber": 0,
                    "myString": "defaultValue"
                ]
            ]
        ]
        
        let messagesDiff: AnyDictionary = [
            "messageId1": [
                "vars": [
                    "myString": "newValue"
                ]
            ]
        ]
        
        let expected: AnyDictionary = [
            "messageId1": [
                "vars": [
                    "myNumber": 0,
                    "myString": "newValue"
                ]
            ]
        ]
        
        let result = ContentMerger.merge(vars: messages, diff: messagesDiff) as! AnyDictionary
        XCTAssertTrue(result.isEqual(expected))
    }
    
    func testMergeDictionaries() {
        let dict: [AnyHashable: Any] = [
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
        
        let dictDiff: [AnyHashable: Any] = [
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
        
        let expected: [AnyHashable: Any] = [
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
        let result = ContentMerger.merge(vars: dict, diff: dictDiff) as! AnyDictionary
        XCTAssertTrue(result.isEqual(expected))
    }
    
    func testMergeDictionariesIncludeDefaults() {
        let dict: AnyDictionary = [
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
        
        let dictDiff: AnyDictionary = [
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
        
        let expected: AnyDictionary = [
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
        
        let result = ContentMerger.merge(vars: dict, diff: dictDiff) as! AnyDictionary
        XCTAssertTrue(expected.isEqual(result))
    }
    
    func testMergeDictionariesIncludeDiffs() {
        let dict: AnyDictionary = [
            "abc": "qwe",
            "nested": [
                "abc": "qwe",
                "1": 123
            ]
        ]
        
        let dictDiff: AnyDictionary = [
            "nested": [
                "qwerty": "qwerty",
                "nested2": [
                    "a": "b"
                    ]
            ]
        ]
        
        let expected: AnyDictionary = [
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

        let result = ContentMerger.merge(vars: dict, diff: dictDiff) as! AnyDictionary
        XCTAssertTrue(expected.isEqual(result))
    }
    
    func testMergeWithEmpty() {
        let dict: AnyDictionary = [
            "abc": "qwe",
            "nested": [
                "abc": "qwe",
                "1": 123
            ]
        ]
        
        let dictDiff: AnyDictionary = [:]

        let result = ContentMerger.merge(vars: dict, diff: dictDiff) as! AnyDictionary
        XCTAssertTrue(dict.isEqual(result))
    }
    
    func testMergeEmpty() {
        let dict: AnyDictionary = [:]
        
        let dictDiff: AnyDictionary = [
            "abc": "qwe",
            "nested": [
                "abc": "qwe",
                "1": 123
            ]
        ]

        let result = ContentMerger.merge(vars: dict, diff: dictDiff) as! AnyDictionary
        XCTAssertTrue(dictDiff.isEqual(result))
    }
    
    func testMergeNull() {
        let dict = NSNull()
        
        let dictDiff: AnyDictionary = [
            "abc": "qwe",
            "nested": [
                "abc": "qwe",
                "1": 123
            ]
        ]
        
        let result = ContentMerger.merge(vars: dict, diff: dictDiff) as! AnyDictionary
        XCTAssertTrue(dictDiff.isEqual(result))
    }
    
    func testMergeWithNull() {
        let dict: AnyDictionary = [
            "abc": "qwe",
            "nested": [
                "abc": "qwe",
                "1": 123
            ]
        ]
        
        let dictDiff = NSNull()
        
        let result = ContentMerger.merge(vars: dict, diff: dictDiff)
        XCTAssertTrue(NSNull().isEqual(result))
    }
}
