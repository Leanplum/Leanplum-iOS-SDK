//
//  MigrationState.swift
//  LeanplumSDK
//
//  Created by Nikola Zagorchev on 2.10.22.
//  Copyright © 2022 Leanplum. All rights reserved.

import Foundation

@objc public enum MigrationState: Int, CustomStringConvertible, CaseIterable {
    
    case undefined = 0,
         leanplum,
         duplicate,
         cleverTap
    
    public var description: String {
        switch self {
        case .undefined:
            return "undefined"
        case .leanplum:
            return "lp"
        case .duplicate:
            return "lp+ct"
        case .cleverTap:
            return "ct"
        }
    }
    
    public init(stringValue: String) {
        let value = Self.allCases.first {
            $0.description == stringValue
        }
        self = value ?? .undefined
    }
    
    var useLeanplum: Bool {
        self != .cleverTap
    }
    
    var useCleverTap: Bool {
        self == .cleverTap || self == .duplicate
    }
}
