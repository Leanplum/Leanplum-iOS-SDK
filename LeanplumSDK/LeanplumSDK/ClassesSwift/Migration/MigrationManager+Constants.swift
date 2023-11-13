//
//  MigrationManager+Constants.swift
//  LeanplumSDK
//
//  Created by Nikola Zagorchev on 2.10.22.
//  Copyright © 2023 Leanplum. All rights reserved.

import Foundation

@objc extension MigrationManager {
    enum Constants {
        static let AccountIdKey = "__leanplum_ct_account_key"
        static let HashKey = "__leanplum_ct_hash_key"
        static let AccountTokenKey = "__leanplum_ct_account_token"
        static let MigrationStateKey = "__leanplum_migration_state"
        static let RegionCodeKey = "__leanplum_region_code"
        static let AttributeMappingsKey = "__leanplum_attribute_mappings"
        static let IdentityKeysKey = "__leanplum_identity_keys"
        static let LoggedInUserIdKey = "__leanplum_logged_in_user_id"
        
        static let DefaultIdentityKeys = [IdentityManager.Constants.Identity]
        
        static let CleverTapRequestArg = "ct"
    }
    
    @objc
    public class func lpCleverTapRequestArg() -> String {
        return Constants.CleverTapRequestArg
    }
}
