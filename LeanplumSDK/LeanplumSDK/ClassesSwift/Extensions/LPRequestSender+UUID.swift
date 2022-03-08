//
//  ApiConfig.swift
//  LeanplumSDK
//
//  Created by Nikola Zagorchev on 10.02.22.
//

import Foundation

extension LPRequestSender {
    enum Constants {
        // LEANPLUM_DEFAULTS_UUID_KEY
        static let uuidKey = "__leanplum_uuid"
    }
    
    @objc public var uuid: String {
        get {
            if let uuid = UserDefaults.standard.string(forKey: Constants.uuidKey) {
                return uuid
            }
            // Ensure UUID is set and returned
            self.uuid = UUID().uuidString.lowercased()
            return self.uuid
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: Constants.uuidKey)
        }
    }
}
