//
//  Wrapper.swift
//  LeanplumSDK
//
//  Created by Nikola Zagorchev on 6.10.22.
//

protocol Wrapper {
    /// Launches the wrapper instance,
    /// equivalent to Leanplum start
    func launch()
    
    /// Sets instance callback when wrapper has initialized
    func setInstanceCallback(_ callback: ((Any) -> Void)?)
    
    func track(_ eventName: String?, value: Double, info: String?, params: [String: Any])
    
    func trackPurchase(_ eventName: String?, value: Double, currencyCode: String?, params: [String: Any])
    
    func advance(_ stateName: String?, info: String?, params: [String: Any])
    
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
