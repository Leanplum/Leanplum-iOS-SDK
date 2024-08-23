//
//  MigrationManager+API.swift
//  LeanplumSDK
//
//  Created by Nikola Zagorchev on 6.10.22.
//  Copyright © 2023 Leanplum. All rights reserved.

@objc public extension MigrationManager {
    var state: MigrationState {
        return migrationState
    }
    
    var cleverTapAccountId: String? {
        return accountId
    }
    
    var cleverTapAccountToken: String? {
        return accountToken
    }
    
    var cleverTapAccountRegion: String? {
        return regionCode
    }
    
    var cleverTapAttributeMappings: [String: String] {
        return attributeMappings
    }
    
    var cleverTapIdentityKeys: [String] {
        return identityKeys
    }
    
    var hasLaunched: Bool {
        guard let wrapper = wrapper else { return false }
        
        return wrapper.hasLaunched
    }
    
    // Expose to ObjC
    var useLeanplum: Bool {
        migrationState.useLeanplum
    }

    // Expose to ObjC
    var useCleverTap: Bool {
        migrationState.useCleverTap
    }

    func track(_ eventName: String?, value: Double, info: String?, params: [String: Any]) {
        wrapper?.track(eventName, value: value, params: params)
    }

    func trackPurchase(_ eventName: String?, value: Double, currencyCode: String?, params: [String: Any]) {
        wrapper?.trackPurchase(eventName, value: value, currencyCode: currencyCode, params: params)
    }

    func trackInAppPurchase(_ eventName: String?,
                            value: Double,
                            currencyCode: String?,
                            iOSTransactionIdentifier: String?,
                            iOSReceiptData: String?,
                                  iOSSandbox: Bool,
                            params: [String: Any]) {
        wrapper?.trackInAppPurchase(eventName,
                                    value: value,
                                    currencyCode: currencyCode,
                                    iOSTransactionIdentifier: iOSTransactionIdentifier,
                                    iOSReceiptData: iOSReceiptData,
                                    iOSSandbox: iOSSandbox,
                                    params: params)
    }

    func advance(_ eventName: String?, info: String?, params: [String: Any]) {
        wrapper?.advance(eventName, params: params)
    }

    func setUserAttributes(_ attributes: [AnyHashable: Any]) {
        wrapper?.setUserAttributes(attributes)
    }

    func setUserId(_ userId: String) {
        wrapper?.setUserId(userId)
    }
    
    func setPushToken(_ token: Data) {
        wrapper?.setPushToken(token)
    }
    
    func setTrafficSourceInfo(_ info: [AnyHashable: Any]) {
        wrapper?.setTrafficSourceInfo(info)
    }

    func addInstanceCallback(_ callback: CleverTapInstanceCallback) {
        instanceCallbacks.append(callback)
        wrapper?.addInstanceCallback(callback)
    }
    
    func removeInstanceCallback(_ callback: CleverTapInstanceCallback) {
        guard let index = instanceCallbacks.firstIndex(of: callback) else { return }
        instanceCallbacks.remove(at: index)
        wrapper?.removeInstanceCallback(callback)
    }
    
    func setLogLevel(_ level: LeanplumLogLevel) {
        wrapper?.setLogLevel(level)
    }
}
