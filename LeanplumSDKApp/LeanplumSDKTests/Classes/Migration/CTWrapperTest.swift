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
    let wrapper = CTWrapper(accountId: "", accountToken: "", accountRegion: "", userId: "", deviceId: "", callbacks: [])
    
    override class func setUp() {
        MigrationManager.shared.attributeMappings = attributeMappings
    }

    func testValuesIsNil() {
        let notNil = "some"
        let notNilOptional:String? = "some"
        let nilString: String? = nil
        let `nil` = nilString as Any
        
        XCTAssertFalse(wrapper.isAnyNil(notNil))
        XCTAssertFalse(wrapper.isAnyNil(notNilOptional as Any))
        XCTAssertTrue(wrapper.isAnyNil(nilString as Any))
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
        let values = ["lpName": "ct value",
                          "number": 4,
                          "arr": ["a", 1, "b", 2],
                          "arrStr": ["a", "b"],
                          "arrNumber": [0.5, 1.2, 2.5],
                          "lpName2": "ct value 2",
                      "empty": nil] as [String : Any?]
        
        let attributes = values as [AnyHashable : Any]
        
        
        let actual = attributes.mapValues(wrapper.transformArrayValues)
            .mapKeys(wrapper.transformAttributeKeys)
        
        let expected = ["ctName": "ct value",
                        "number": 4,
                        "arr": "[a,1,b,2]",
                        "arrStr": "[a,b]",
                        "arrNumber": "[0.5,1.2,2.5]",
                        "ctName2": "ct value 2",
                        "empty": nil] as [String : Any?]
        
        XCTAssertTrue(actual.isEqual(expected as [AnyHashable : Any]))
    }
    
    func testAttributeValuesNil() {
        let attributes = ["arr": ["a", 1, "b", 2.0, true, nil]] as [AnyHashable : Any]
        
        let actual = attributes.mapValues(wrapper.transformArrayValues)
            .mapKeys(wrapper.transformAttributeKeys)
        
        let expected = ["arr": "[a,1,b,2.0,true]"] as [AnyHashable : Any]
        XCTAssertTrue(actual.isEqual(expected))
    }
    
    func testAttributeValuesNotNil() {
        let attributes = ["arr": ["a", 1, "b", 2.0, true]] as [AnyHashable : Any]
        
        let actual = attributes.mapValues(wrapper.transformArrayValues)
            .mapKeys(wrapper.transformAttributeKeys)
        
        let expected = ["arr": "[a,1,b,2.0,true]"] as [AnyHashable : Any]
        XCTAssertTrue(actual.isEqual(expected))
    }
    
    func testAttributeValuesNSNull() {
        let attributes = ["arr": ["a", 1.99, "b", 2, true, false, 0, NSNull()]] as [AnyHashable : Any]
        let attributesWithNil = ["arr": ["a", 1.99, "b", 2, nil, true, false, 0, NSNull(), nil]] as [AnyHashable : Any]
        
        let actual = attributes.mapValues(wrapper.transformArrayValues)
            .mapKeys(wrapper.transformAttributeKeys)
        let actualWithNil = attributesWithNil.mapValues(wrapper.transformArrayValues)
            .mapKeys(wrapper.transformAttributeKeys)
        
        let expected = ["arr": "[a,1.99,b,2,true,false,0,<null>]"] as [AnyHashable : Any]
        XCTAssertTrue(actual.isEqual(expected))
        XCTAssertTrue(actualWithNil.isEqual(expected))
    }
}
