//
//  WrapperTest.swift
//  LeanplumSDKTests
//
//  Created by Nikola Zagorchev on 5.10.22.
//

import Foundation
import XCTest
@testable import Leanplum

class WrapperTest: XCTestCase {
    
    static let attributeMappings = ["lpName": "ctName", "lpName2": "ctName2"]
    let wrapper = CTWrapper(accountId: "", accountToken: "", accountRegion: "", userId: "", deviceId: "", callback: nil)
    
    override class func setUp() {
        MigrationManager.shared.attributeMappings = attributeMappings
    }

    func testValuesIsNil() {
        let notNil = "some"
        let notNilOptional:String? = "some"
        let nilString: String? = nil
        let `nil` = nilString as Any
        
        XCTAssertFalse(wrapper.isAnyNil(notNil))
        XCTAssertFalse(wrapper.isAnyNil(notNilOptional))
        XCTAssertTrue(wrapper.isAnyNil(nilString))
        XCTAssertTrue(wrapper.isAnyNil(`nil`))
    }
    
    func testAttributeKeys() {
        let attributes = ["lpName": "ct value",
                          "lpName1": "ct value 1",
                          "lpName2": "ct value 2"] as [AnyHashable : Any]
        
        
        let actual = attributes.mapKeys(wrapper.transformAttributeKeys)
        
        let expected = ["ctName": "ct value",
                        "lpName1": "ct value 1",
                          "ctName2": "ct value 2"] as [AnyHashable : Any]
        
        XCTAssertTrue(actual.isEqual(expected))
    }
    
    func testAttributeKeysDuplicates() {
        let attributes = ["lpName": "ct value",
                          "ctName": "ct value",
                          "lpName2": "ct value 2"] as [AnyHashable : Any]
        
        
        let actual = attributes.mapKeys(wrapper.transformAttributeKeys)
        // Dictionary is unordered
        let expected = ["ctName": "ct value",
                          "ctName2": "ct value 2"] as [AnyHashable : Any]

        XCTAssertTrue(actual.isEqual(expected))
    }
    
    func testAttributeValues() {
        let attributes = ["lpName": "ct value",
                          "number": 4,
                          "arr": ["a", 1, "b", 2],
                          "arrStr": ["a", "b"],
                          "arrNumber": [0.5, 1.2, 2.5],
                          "lpName2": "ct value 2",
                          "empty": nil] as [AnyHashable : Any]
        
        
        let actual = attributes.mapValues(wrapper.transformAttributeValues)
            .mapKeys(wrapper.transformAttributeKeys)
        
        let expected = ["ctName": "ct value",
                        "number": 4,
                        "arr": "[a,1,b,2]",
                        "arrStr": "[a,b]",
                        "arrNumber": "[0.5,1.2,2.5]",
                        "ctName2": "ct value 2",
                        "empty": nil] as [AnyHashable : Any]
        
        print(actual)
        print(expected)
        XCTAssertTrue(actual.isEqual(expected))
    }
    
    func t() {
        MigrationManager.shared.migrationState = .leanplum 
    }
}
