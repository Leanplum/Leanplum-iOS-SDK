//
//  PropertyWrappers.swift
//  LeanplumSDK
//
//  Created by Nikola Zagorchev on 2.10.22.
//

import Foundation

@propertyWrapper
struct StringOptionalUserDefaults {
    private var key: String

    var wrappedValue: String? {
        get { UserDefaults.standard.string(forKey: key) }
        set { UserDefaults.standard.setValue(newValue, forKey: key) }
    }
    
    init(key: String) {
        self.key = key
    }
}

@propertyWrapper
struct MigrationStateUserDefaults {
    private var key: String
    private var defaultValue: MigrationState
    
    public var wrappedValue: MigrationState {
        get {
            if let value = UserDefaults.standard.string(forKey: key) {
                return MigrationState(stringValue: value)
            }
            return defaultValue
        }
        set { UserDefaults.standard.setValue(newValue.description, forKey: key) }
    }
    
    init(key: String, defaultValue: MigrationState) {
        self.key = key
        self.defaultValue = defaultValue
    }
}

@propertyWrapper
struct PropUserDefaults<T> {
    private var key: String
        private var defaultValue: T
    
    var wrappedValue: T {
        get {
            guard let value = UserDefaults.standard.object(forKey: key) as? T
            else { return defaultValue }
            
            return value
        }
        set { UserDefaults.standard.setValue(newValue, forKey: key) }
    }
    
    init(key: String, defaultValue: T) {
        self.key = key
        self.defaultValue = defaultValue
    }
}
