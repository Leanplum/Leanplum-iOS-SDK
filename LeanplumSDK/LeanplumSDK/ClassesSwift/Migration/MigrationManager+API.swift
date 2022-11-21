//
//  MigrationManager+API.swift
//  LeanplumSDK
//
//  Created by Nikola Zagorchev on 6.10.22.
//  Copyright © 2022 Leanplum. All rights reserved.

@objc public extension MigrationManager {
    
    // Expose to ObjC
    @objc var useLeanplum: Bool {
        migrationState.useLeanplum
    }
    
    // Expose to ObjC
    @objc var useCleverTap: Bool {
        migrationState.useCleverTap
    }
    
    func launch() {
        guard let wrapper = wrapper else {
            Log.debug("[Wrapper] Calling launch before wrapper is initialized.")
            return
        }
        wrapper.launch()
    }
    
    var state: MigrationState {
        return migrationState
    }

    func track(_ eventName: String?, value: Double, info: String?, params: [String: Any]) {
        wrapper?.track(eventName, value: value, info: info, params: params)
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
        wrapper?.advance(eventName, info: info, params: params)
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
