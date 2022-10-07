//
//  Migration+Extensions.swift
//  LeanplumSDKTests
//
//  Created by Nikola Zagorchev on 7.10.22.
//

import Foundation
@testable import Leanplum

@objc public extension MigrationManager {
    @available(iOS 13.0, *)
    func setMigrationState(_ state: MigrationState) {
        migrationState = state
    }
}
