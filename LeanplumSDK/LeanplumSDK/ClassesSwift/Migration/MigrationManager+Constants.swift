//
//  MigrationManager+Constants.swift
//  LeanplumSDK
//
//  Created by Nikola Zagorchev on 2.10.22.
//

import Foundation

@objc extension MigrationManager {
    enum Constants {
        static let AccountIdKey = "__leanplum_ct_account_key"
        static let HashKey = "__leanplum_ct_hash_key"
        static let AccountTokenKey = "__leanplum_ct_account_token"
        static let MigrationStateKey = "__leanplum_migration_state"
        static let RegionCodeKey = "__leanplum_region_code"
        static let AttributeMappingsKey = "__leanplum_attribute_mappings"
        
        static let MigrateStateResponseParam = "migrateState"
        static let MigrateStateNotificationInfo = "migrateState"
        static let SdkResponseParam = "sdk"
        static let CTResponseParam = "ct"
        static let AccountIdResponseParam = "accountId"
        static let AccountTokenResponseParam = "token"
        static let RegionCodeResponseParam = "regionCode"
        static let AttributeMappingsResponseParam = "attributeMappings"
        static let HashResponseParam = "sha256";
        
        static let CleverTapRequestArg = "ct"
    }
    
    @objc
    public class func lpMigrateStateNotificationInfo() -> String {
        return Constants.MigrateStateNotificationInfo
    }
    
    @objc
    public class func lpCleverTapRequestArg() -> String {
        return Constants.CleverTapRequestArg
    }
}
