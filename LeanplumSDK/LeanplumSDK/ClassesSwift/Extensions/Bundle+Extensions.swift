//
//  Bundle+Extensions.swift
//  LeanplumSDK
//
//  Created by Milos Jakovljevic on 24.12.21.
//

import Foundation

extension Bundle {
    static var appName: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ??
        Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? ""
    }
    
    static var identifier: String {
        Bundle.main.bundleIdentifier ?? ""
    }
}
