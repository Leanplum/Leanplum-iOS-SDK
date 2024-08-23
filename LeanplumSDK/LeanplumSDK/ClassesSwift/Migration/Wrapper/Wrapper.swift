//
//  Wrapper.swift
//  LeanplumSDK
//
//  Created by Nikola Zagorchev on 6.10.22.
//  Copyright © 2022 Leanplum. All rights reserved.

protocol Wrapper {
    /// Launches the wrapper instance,
    /// equivalent to Leanplum start
    func launch()
    
    var hasLaunched: Bool { get }
    
    /// Adds instance callback, executed when wrapper has initialized
    func addInstanceCallback(_ callback: CleverTapInstanceCallback)
    
    func removeInstanceCallback(_ callback: CleverTapInstanceCallback)
    
    func track(_ eventName: String?, value: Double, params: [String: Any])
    
    func trackPurchase(_ eventName: String?, value: Double, currencyCode: String?, params: [String: Any])
    
    func advance(_ stateName: String?, params: [String: Any])
    
    func trackInAppPurchase(_ eventName: String?,
                            value: Double,
                            currencyCode: String?,
                            iOSTransactionIdentifier: String?,
                            iOSReceiptData: String?,
                            iOSSandbox: Bool,
                            params: [String: Any])
    
    func setUserAttributes(_ attributes: [AnyHashable: Any])
    
    func setUserId(_ userId: String)
    
    func setPushToken(_ token: Data)
    
    func setTrafficSourceInfo(_ info: [AnyHashable: Any])
    
    func setLogLevel(_ level: LeanplumLogLevel)
}
