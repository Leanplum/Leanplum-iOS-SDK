//
//  ApiConfig.swift
//  LeanplumSDK
//
//  Created by Nikola Zagorchev on 11.02.22.
//  Copyright © 2022 Leanplum. All rights reserved.

import Foundation

@objc public class ApiConfig: NSObject {
    enum Constants {
        static let apiHostKey = "__leanplum_api_host"
        static let apiServletKey = "__leanplum_api_servlet"
        static let socketHostKey = "__leanplum_socket_host"
        
        // LP_KEYCHAIN_SERVICE_NAME
        static let keyChainServiceName = "com.leanplum.storage";
        // LP_KEYCHAIN_USERNAME
        static let keyChainUserName = "defaultUser";
        
        static let apiHostName = "api.leanplum.com";
        static let apiPath = "api";
        static let apiSSL = true
        static let socketHost = "dev.leanplum.com";
        static let socketPort = 443;
    }
    
    private override init() {}
    
    @objc public static let shared: ApiConfig = .init()
    
    @objc public private(set) var appId: String?
    @objc public private(set) var accessKey: String?
    
    @objc public var socketPort = Constants.socketPort
    @objc public var apiSSL = Constants.apiSSL
    
    @objc public var token: String? {
        get {
            do {
                let savedToked = try LPKeychainWrapper
                    .getPasswordForUsername(Constants.keyChainUserName,
                                            andServiceName: Constants.keyChainServiceName)
                return savedToked
            } catch {
                Log.error("Error getting token from keychain: \(error).")
            }
            return nil
        }
        set {
            do {
                try LPKeychainWrapper.storeUsername(Constants.keyChainUserName,
                                                    andPassword: newValue,
                                                    forServiceName: Constants.keyChainServiceName,
                                                    updateExisting: true)
            } catch {
                Log.error("Error storing token in keychain: \(error).")
            }
        }
    }
    
    @objc public var apiHostName: String {
        get {
            if let apiHostName = UserDefaults.standard.string(forKey: Constants.apiHostKey) {
                return apiHostName
            }
            return Constants.apiHostName
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: Constants.apiHostKey)
        }
    }
    
    @objc public var apiPath: String {
        get {
            if let apiServlet = UserDefaults.standard.string(forKey: Constants.apiServletKey) {
                return apiServlet
            }
            return Constants.apiPath
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: Constants.apiServletKey)
        }
    }
    
    @objc public var socketHost: String {
        get {
            if let socketHost = UserDefaults.standard.string(forKey: Constants.socketHostKey) {
                return socketHost
            }
            return Constants.socketHost
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: Constants.socketHostKey)
        }
    }
    
    @objc public func setAppId(_ appId: String, accessKey: String) {
        self.appId = appId;
        self.accessKey = accessKey;
    }
    
    @objc public static func attachApiKeys(dict: NSMutableDictionary) {
        dict[LP_PARAM_APP_ID] = ApiConfig.shared.appId;
        dict[LP_PARAM_CLIENT_KEY] = ApiConfig.shared.accessKey;
    }
}
