//
//  Bundle+Extensions.swift
//  LeanplumSDK
//
//  Created by Milos Jakovljevic on 24.12.21.
//

import Foundation

extension Bundle {
    
    static let bundleDisplayNameKey: String = "CFBundleDisplayName"
    static let bundleNameKey: String = "CFBundleName"
    
    static var appName: String {
        Bundle.main.object(forInfoDictionaryKey: Bundle.bundleDisplayNameKey) as? String ??
        Bundle.main.object(forInfoDictionaryKey: Bundle.bundleNameKey) as? String ?? ""
    }
    
    static var identifier: String {
        Bundle.main.bundleIdentifier ?? ""
    }
}
