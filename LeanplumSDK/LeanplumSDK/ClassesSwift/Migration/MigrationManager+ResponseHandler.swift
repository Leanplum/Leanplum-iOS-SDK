//
//  MigrationManager+ResponseHandler.swift
//  LeanplumSDK
//
//  Created by Nikola Zagorchev on 3.10.22.
//

import Foundation

@objc public extension MigrationManager {
    //    migrateState =     {
    //        sha256 = 31484a565dcd3e1672922c7c4166bfeee0f500b6d6473fc412091304cc162ca8;
    //    };
    @objc
    func handleMigrateState(multiApiResponse: Any) {
        guard let migrateState = getValue(dict: multiApiResponse,
                                          key: Constants.MigrateStateResponseParam)
        else { return }
        
        if let hash = getValue(dict: migrateState, key: Constants.HashKey) as? String,
           hash != self.migrationHash {
            Log.debug("CleverTap Hash changed")
            
            self.migrationHash = hash
            
            fetchMigrationStateAsync {}
        }
    }
    
    //    response =     (
    //                {
    //            api =             {
    //                events = "lp+ct";
    //                profile = "lp+ct";
    //            };
    //            ct =             {
    //                accountId = "accId";
    //                attributeMappings =                 {
    //                    name1 = "ct-name1";
    //                };
    //                regionCode = eu1;
    //                token = "token";
    //            };
    //            eventsUploadStartedTs = "2022-10-02T17:46:01.356Z";
    //            profileUploadStartedTs = "2022-10-02T17:46:01.356Z";
    //            reqId = "A285641F-9903-4182-8A10-EB42782CAE69";
    //            sdk = "lp+ct";
    //            sha256 = 31484a565dcd3e1672922c7c4166bfeee0f500b6d6473fc412091304cc162ca8;
    //            state = "EVENTS_UPLOAD_STARTED";
    //            success = 1;
    //        }
    //    );
    func handleGetMigrateState(apiResponse: Any) {
        if let ct = getValue(dict: apiResponse, key: Constants.CTResponseParam) {
            if let id = getValue(dict: ct, key: Constants.AccountIdResponseParam) as? String {
                accountId = id
            }
            if let token = getValue(dict: ct, key: Constants.AccountTokenResponseParam) as? String {
                accountToken = token
            }
            if let region = getValue(dict: ct, key: Constants.RegionCodeResponseParam) as? String {
                regionCode = region
            }
            if let mappings = getValue(dict: ct, key: Constants.AttributeMappingsResponseParam) as? [String: String] {
                attributeMappings = mappings
            }
        }
        
        if let sdk = getValue(dict: apiResponse, key: Constants.SdkResponseParam) as? String {
            migrationState = MigrationState(stringValue: sdk)
        }
        if let hash = getValue(dict: apiResponse, key: Constants.HashKey) as? String {
            migrationHash = hash
        }
    }
    
    private func getValue(dict: Any, key: String) -> Any? {
        guard let dict = dict as? [String: Any] else {
            return nil
        }
        
        return dict[key]
    }
}
