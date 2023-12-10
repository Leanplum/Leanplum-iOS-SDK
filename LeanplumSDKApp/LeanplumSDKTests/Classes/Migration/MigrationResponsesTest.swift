//
//  MigrationResponsesTest.swift
//  LeanplumSDKTests
//
//  Created by Nikola Zagorchev on 9.02.23.
//  Copyright © 2023 Leanplum. All rights reserved.

import Foundation
import XCTest
@testable import Leanplum

class MigrationResponsesTest: XCTestCase {
    
    struct Responses {
        static let get_migrate_state_response = "get_migrate_state_response"
        static let get_migrate_state_response_error = "get_migrate_state_response_error"
        static let get_migrate_state_response_missing = "get_migrate_state_response_missing"
        static let jsonType = "json"
    }
    
    func testMigrationResponse() {
        if let path = Bundle.main.path(forResource: Responses.get_migrate_state_response, ofType: Responses.jsonType) {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                let jsonResult = try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
                let migrationData = MigrationManager.shared.parseResponse(apiResponse: jsonResult)
                
                let ctConfig = MigrationManager.CTConfig(accountID: "accId",
                                                         token: "token",
                                                         regionCode: "eu1",
                                                         attributeMappings: ["name1": "ct-name1",],
                                                         identityKeys: ["Identity", "Email"])
                
                let expectedData = MigrationManager.MigrationData(ct: ctConfig,
                                                                  migrationState: "lp+ct",
                                                                  hash: "31484a565dcd3e1672922c7c4166bfeee0f500b6d6473fc412091304cc162ca8",
                                                                  loggedInUserId: nil)
                
                XCTAssertEqual(migrationData, expectedData)
            } catch {
                XCTFail(String(describing: error))
            }
        }
    }
    
    func testMigrationResponseMissingKeys() {
        if let path = Bundle.main.path(forResource: Responses.get_migrate_state_response_missing, ofType: Responses.jsonType) {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                let jsonResult = try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
                let migrationData = MigrationManager.shared.parseResponse(apiResponse: jsonResult)
                
                let ctConfig = MigrationManager.CTConfig(accountID: nil,
                                                         token: "token",
                                                         regionCode: "eu1",
                                                         attributeMappings: ["name1": "ct-name1",],
                                                         identityKeys: nil)
                
                let expectedData = MigrationManager.MigrationData(ct: ctConfig,
                                                                  migrationState: nil,
                                                                  hash: nil,
                                                                  loggedInUserId: nil)
                
                XCTAssertEqual(migrationData, expectedData)
            } catch {
                XCTFail(String(describing: error))
            }
        }
    }
    
    func testMigrationResponseError() {
        // The JSON has a type mismatch - individualKeys is of type String where expected type is String Array
        if let path = Bundle.main.path(forResource: Responses.get_migrate_state_response_error, ofType: Responses.jsonType) {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                let jsonResult = try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
                let migrationData = MigrationManager.shared.parseResponse(apiResponse: jsonResult)
                
                // If there is an error, the MigrationData will be nil
                XCTAssertEqual(migrationData, nil)
            } catch {
                XCTFail(String(describing: error))
            }
        }
    }
}
