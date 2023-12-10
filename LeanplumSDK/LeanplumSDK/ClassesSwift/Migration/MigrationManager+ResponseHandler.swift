//
//  MigrationManager+ResponseHandler.swift
//  LeanplumSDK
//
//  Created by Nikola Zagorchev on 3.10.22.
//  Copyright © 2023 Leanplum. All rights reserved.

import Foundation

@objc public extension MigrationManager {
    
    // MARK: - ResponseParams
    enum ResponseParams {
        static let MigrateState = "migrateState"
        static let Hash = "sha256";
    }
    
    // MARK: - MigrationData
    struct MigrationData: Codable, Equatable {
        let ct: CTConfig?
        let migrationState: String?
        let hash: String?
        let loggedInUserId: String?
        
        enum CodingKeys: String, CodingKey {
            case hash = "sha256"
            case migrationState = "sdk"
            case ct
            case loggedInUserId
        }
    }

    // MARK: - CTConfig
    struct CTConfig: Codable, Equatable {
        let accountID: String?
        let token: String?
        let regionCode: String?
        let attributeMappings: [String: String]?
        let identityKeys: [String]?

        enum CodingKeys: String, CodingKey {
            case accountID = "accountId"
            case token, regionCode, attributeMappings, identityKeys
        }
    }
    
    // MARK: - Handle Responses
    //    migrateState = {
    //        sha256 = 31484a565dcd3e1672922c7c4166bfeee0f500b6d6473fc412091304cc162ca8;
    //    };
    @objc
    func handleMigrateState(multiApiResponse: Any) {
        guard let migrateState = getValue(dict: multiApiResponse,
                                          key: ResponseParams.MigrateState)
        else { return }
        
        if let hash = getValue(dict: migrateState, key: ResponseParams.Hash) as? String,
           hash != self.migrationHash {
            Log.debug("[Wrapper] CleverTap Hash changed")
            fetchMigrationStateAsync {}
        }
    }
    
    //    "response": [
    //        {
    //            "api": {
    //                "events": "lp+ct",
    //                "profile": "lp+ct",
    //            },
    //            "ct": {
    //                "accountId": "accId",
    //                "attributeMappings": {
    //                    "name1": "ct-name1",
    //                },
    //                "identityKeys": ["Identity", "Email"],
    //                "regionCode": "eu1",
    //                "token": "token",
    //            },
    //            "eventsUploadStartedTs": "2022-10-02T17:46:01.356Z",
    //            "profileUploadStartedTs": "2022-10-02T17:46:01.356Z",
    //            "reqId": "A285641F-9903-4182-8A10-EB42782CAE69",
    //            "sdk": "lp+ct",
    //            "sha256": "31484a565dcd3e1672922c7c4166bfeee0f500b6d6473fc412091304cc162ca8",
    //            "state": "EVENTS_UPLOAD_STARTED",
    //            "loggedInUserId": "9da5cdc6-m340-42a8-9110-1d4a1099f157",
    //            "success": 1,
    //        }
    //    ]
    func handleGetMigrateState(apiResponse: Any) {
        guard let migrationData = parseResponse(apiResponse: apiResponse) else {
            return
        }
        
        if let ct = migrationData.ct {
            if let id = ct.accountID {
                accountId = id
            }
            if let token = ct.token {
                accountToken = token
            }
            if let region = ct.regionCode {
                regionCode = region
            }
            if let mappings = ct.attributeMappings {
                attributeMappings = mappings
            }
            if let keys = ct.identityKeys, keys.count > 0 {
                identityKeys = keys
            }
        }
        
        if let hash = migrationData.hash {
            migrationHash = hash
        }
        
        if let loggedInUser = migrationData.loggedInUserId {
            loggedInUserId = loggedInUser
            Leanplum.onStartResponse { _ in
                if Leanplum.userId() == Leanplum.deviceId() {
                    Leanplum.setUserId(loggedInUser)
                }
            }
        }
        
        // Changing the migrationState value will initialize the Wrapper
        if let sdk = migrationData.migrationState {
            migrationState = MigrationState(stringValue: sdk)
        }
    }
    
    // MARK: - Utils
    @nonobjc internal func parseResponse(apiResponse: Any) -> MigrationData? {
        if let dict = apiResponse as? [String: Any] {
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted)
                return try JSONDecoder().decode(MigrationData.self, from: jsonData)
            } catch {
                Log.error("[Wrapper] Error parsing getMigrateState response: \(error.localizedDescription), error: \(String(describing: error))")
            }
        }
        return nil
    }
    
    private func getValue(dict: Any, key: String) -> Any? {
        guard let dict = dict as? [String: Any] else {
            return nil
        }
        
        return dict[key]
    }
}
