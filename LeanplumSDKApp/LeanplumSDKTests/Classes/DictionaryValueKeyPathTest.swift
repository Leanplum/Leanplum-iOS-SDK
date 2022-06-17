//
//  DictionaryExtensionsTest.swift
//  LeanplumSDKTests
//
//  Created by Nikola Zagorchev on 18.05.22.
//

import Foundation

import XCTest
@testable import Leanplum

class DictionaryValueKeyPathTest: XCTestCase {
    func testGetValue() {
        let dict: [AnyHashable: Any] = [
            "first": "1",
            "second": [1, 2]
        ]
        
        XCTAssertEqual(dict[valueKeyPath: "first"] as? String, "1")
        XCTAssertEqual(dict[valueKeyPath: "second"] as? Array, [1, 2])
    }
    
    func testGetNestedValue() {
        let dict: [AnyHashable: Any] = [
            "first": [
                "nested": "1",
                "nestedDict": [
                    "key1": "value1"
                ]
            ]
        ]
        
        XCTAssertEqual(dict[valueKeyPath: "first.nested"] as? String, "1")
        XCTAssertEqual(dict[valueKeyPath: "first.nestedDict.key1"] as? String, "value1")
    }
    
    func testGetNestedDictionary() {
        let dict: [AnyHashable: Any] = [
            "first": [
                "nested": "1"
            ]
        ]
        
        XCTAssertEqual(dict[valueKeyPath: "first"] as? [String: String], [
            "nested": "1"
        ])
    }
    
    func testSetValue() {
        var dict: [AnyHashable: Any] = [:]
        dict[valueKeyPath: "first"] = "1"
        
        XCTAssertEqual(dict["first"] as? String, "1")
    }
    
    func testSetNestedValue() {
        var dict: [AnyHashable: Any] = [:]
        dict[valueKeyPath: "first.nested"] = "1"
        
        let value = (dict["first"] as! [AnyHashable: Any])["nested"] as? String
        XCTAssertEqual(value, "1")
        XCTAssertEqual(dict[valueKeyPath: "first.nested"] as? String, "1")
    }
    
    func testSetNestedDictionary() {
        var dict: [AnyHashable: Any] = [:]
        dict[valueKeyPath: "first.nested"] = [
            "key1": "value1"
        ]
        
        let value = (dict["first"] as! [AnyHashable: Any])["nested"]
        XCTAssertEqual(value as! [String : String], [
            "key1": "value1"
        ])
        XCTAssertEqual(dict[valueKeyPath: "first.nested"] as! [String : String], [
            "key1": "value1"
        ])
    }
    
    func testSetNestedDictionaryNestedKey() {
        var dict: [AnyHashable: Any] = [:]
        dict[valueKeyPath: "first.nested.key"] = [
            "key1": "value1"
        ]
        
        let value = ((dict["first"] as! [AnyHashable: Any])["nested"] as! [AnyHashable: Any])["key"]
        XCTAssertEqual(value as! [String : String], [
            "key1": "value1"
        ])
        XCTAssertEqual(dict[valueKeyPath: "first.nested.key"] as! [String : String], [
            "key1": "value1"
        ])
    }
}
