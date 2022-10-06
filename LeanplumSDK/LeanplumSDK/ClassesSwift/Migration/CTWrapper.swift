//
//  CTWrapper.swift
//  LeanplumSDK
//
//  Created by Nikola Zagorchev on 9.07.22.
//

import Foundation
// Use @_implementationOnly to *not* expose CleverTapSDK to the Leanplum-Swift header
@_implementationOnly import CleverTapSDK

class CTWrapper {
    enum Constants {
        static let StatePrefix = "state_"
        static let UTMVisitedEvent = "UTM Visited"
        
        static let ValueParamName = "value"
        static let InfoParamName = "info"
        static let ChargedEventParam = "event"
        static let CurrencyCodeParam = "currencyCode"
        static let iOSTransactionIdentifierParam = "iOSTransactionIdentifier"
        static let iOSReceiptDataParam = "iOSReceiptData"
        static let iOSSandboxParam = "iOSSandbox"
    }
    
    var cleverTapInstance: CleverTap?
    var instanceCallback: ((Any) -> Void)?
    
    var accountId: String
    var accountToken: String
    var accountRegion: String
    var identityManager: IdentityManager
    
    // MARK: Initialization
    public init(accountId: String,
                accountToken: String,
                accountRegion: String,
                userId: String,
                deviceId: String,
                callback: ((Any) -> Void)?) {
        Log.debug("Wrapper: Wrapper Instantiated")
        self.accountId = accountId
        self.accountToken = accountToken
        self.accountRegion = accountRegion
        self.instanceCallback = callback
        
        identityManager = IdentityManager(userId: userId, deviceId: deviceId)
        setLogLevel(LPLogManager.logLevel())
    }
    
    public func launch() {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [self] in
                launch()
            }
            return
        }

        let config = CleverTapInstanceConfig.init(accountId: accountId, accountToken: accountToken, accountRegion: accountRegion)
        config.useCustomCleverTapId = true
        cleverTapInstance = CleverTap.instance(with: config, andCleverTapID: identityManager.cleverTapID)
        cleverTapInstance?.setLibrary("Leanplum")
        
        Log.debug("Wrapper: CleverTap instance created with accountId: \(accountId) and accountToken: \(accountToken)")
        //CleverTap.sharedInstance()?.notifyApplicationLaunched(withOptions: nil)
        
        if !identityManager.isAnonymous {
            Log.debug("Wrapper: will call onUserLogin with identity: \(identityManager.userId) and cleverTapId: \(identityManager.cleverTapID)")
            cleverTapInstance?.onUserLogin(identityManager.profile,
                                           withCleverTapID: identityManager.cleverTapID)
        }
        triggerInstanceCallback()
    }
    
    func triggerInstanceCallback() {
        guard let callback = instanceCallback, let instance = cleverTapInstance else {
            return
        }
        
        callback(instance)
    }
    
    func setInstanceCallback(_ callback: ((Any) -> Void)?) {
        instanceCallback = callback
        triggerInstanceCallback()
    }

    // MARK: Events
    func track(_ eventName: String?, value: Double, info: String?, params: [String: Any]) {
        
        // message impression events come with event: nil
        guard let eventName = eventName else {
            return
        }
    
        var eventParams = params.mapValues(transformAttributeValues)
        eventParams[Constants.ValueParamName] = value
        
        if let info = info {
            eventParams[Constants.InfoParamName] = info
        }

        Log.debug("Leanplum.track will call recordEvent with \(eventName) and \(eventParams)")
        cleverTapInstance?.recordEvent(eventName, withProps: eventParams)
    }
    
    func advance(_ stateName: String?, info: String?, params: [String: Any]) {
        guard let stateName = stateName else {
            return
        }
        
        let eventName = Constants.StatePrefix + stateName
        Log.debug("Leanplum.advance will call track with \(eventName) and \(params)")
        track(eventName, value: 0.0, info: info, params: params)
    }
    
    func trackPurchase(_ eventName: String?, value: Double, currencyCode: String?, params: [String: Any]) {
        guard let eventName = eventName else {
            return
        }
    
        var details = params.mapValues(transformAttributeValues)
        details[Constants.ChargedEventParam] = eventName
        details[Constants.ValueParamName] = value
        
        if let currencyCode = currencyCode {
            details[Constants.CurrencyCodeParam] = currencyCode
        }
        
        let items: [Any] = []

        Log.debug("Wrapper: Leanplum.trackPurchase will call recordChargedEvent with \(details) and \(items)")
        cleverTapInstance?.recordChargedEvent(withDetails: details, andItems: items)
    }
    
    func trackInAppPurchase(_ eventName: String?, value: Double, currencyCode: String?,
                            iOSTransactionIdentifier: String?, iOSReceiptData: String?,
                            iOSSandbox: Bool, params: [String: Any]) {
        guard let eventName = eventName else {
            return
        }
        
        // item and quantity are already in the parameters
        // and they are the only ones
        var details = params.mapValues(transformAttributeValues)
        details[Constants.ChargedEventParam] = eventName
        details[Constants.ValueParamName] = value
        
        if let currencyCode = currencyCode {
            details[Constants.CurrencyCodeParam] = currencyCode
        }
        if let iOSTransactionIdentifier = iOSTransactionIdentifier {
            details[Constants.iOSTransactionIdentifierParam] = iOSTransactionIdentifier
        }
        if let iOSReceiptData = iOSReceiptData {
            details[Constants.iOSReceiptDataParam] = iOSReceiptData
        }
        details[Constants.iOSSandboxParam] = iOSSandbox
        
        let items: [Any] = []

        Log.debug("Wrapper: Leanplum.trackInAppPurchase will call recordChargedEvent with \(details) and \(items)")
        cleverTapInstance?.recordChargedEvent(withDetails: details, andItems: items)
    }
    
    func setUserAttributes(_ attributes: [AnyHashable: Any]) {
        // .compactMapValues { $0 } will not work on not optional type Any which can still hold nil
        let profileAttributes = attributes
            .filter { !isAnyNil($0.value) }
            .mapValues(transformAttributeValues)
            .mapKeys(transformAttributeKeys)
        
        Log.debug("Wrapper: Leanplum.setUserAttributes will call profilePush with \(profileAttributes)")
        cleverTapInstance?.profilePush(profileAttributes)
        
        attributes
            .filter { isAnyNil($0.value) }
            .mapKeys(transformAttributeKeys)
            .forEach {
                Log.debug("Wrapper: Leanplum.setUserAttributes will call profileRemoveValue forKey: \($0.key)")
                cleverTapInstance?.profileRemoveValue(forKey: String(describing: $0.key))
            }
    }
    
    func isAnyNil(_ value: Any) -> Bool {
        if case Optional<Any>.none = value {
            return true
        }
        return false
    }
    
    var transformAttributeValues: ((Any) -> Any) {
        return { value in
            if let arr = value as? Array<Any> {
                let arrString = arr.map {
                    String(describing: $0)
                }
                return ("[\(arrString.joined(separator: ","))]") as Any
            }
            return value
        }
    }
    
    var transformAttributeKeys: ((AnyHashable) -> AnyHashable) {
        return { key in
            guard let keyStr = key as? String,
            let newKey = MigrationManager.shared.attributeMappings[keyStr]
            else {
                return key
            }

            return newKey
        }
    }
    
    // MARK: Identity
    
    public func setUserId(_ userId: String) {
        guard userId != identityManager.userId else { return }
        
        identityManager.setUserId(userId)
        
        let profile = identityManager.profile
        let cleverTapID = identityManager.cleverTapID
        
        Log.debug("""
                Wrapper: Leanplum.setUserId will call onUserLogin \
                with identity: \(profile) \
                and CleverTapID:  \(cleverTapID)")
                """)
        cleverTapInstance?.onUserLogin(profile, withCleverTapID: cleverTapID)
    }
    
    func setTrafficSourceInfo(_ info: [AnyHashable: Any]) {
        let trafficSourceInfoMappings = [
            "publisherId": "utm_source_id",
            "publisherName": "utm_source",
            "publisherSubPublisher": "utm_medium",
            "publisherSubSite": "utm_subscribe.site",
            "publisherSubCampaign": "utm_campaign",
            "publisherSubAdGroup": "utm_sourcepublisher.ad_group",
            "publisherSubAd": "utm_SourcePublisher.ad"
        ]
        
        let props = info.mapKeys({ key in
            guard let keyStr = key as? String,
            let newKey = trafficSourceInfoMappings[keyStr]
            else {
                return key
            }
            return newKey
        })
        
        Log.debug("Wrapper: Leanplum.setTrafficSourceInfo will call pushEvent with \(Constants.UTMVisitedEvent) and \(props)")
        cleverTapInstance?.recordEvent(Constants.UTMVisitedEvent, withProps: props)
    }
    
    func setLogLevel(_ level: LeanplumLogLevel) {
        switch level {
        case .off:
            CleverTap.setDebugLevel(CleverTapLogLevel.off.rawValue)
        case .error, .info:
            CleverTap.setDebugLevel(CleverTapLogLevel.info.rawValue)
        case .debug:
            CleverTap.setDebugLevel(CleverTapLogLevel.debug.rawValue)
        default:
            CleverTap.setDebugLevel(CleverTapLogLevel.info.rawValue)
        }
    }
}

public extension Dictionary {
    /// Transforms dictionary keys without modifying values.
    /// Deduplicates transformed keys, by choosing the first value.
    ///
    /// Example:
    /// ```
    /// ["one": 1, "two": 2, "three": 3, "": 4].mapKeys({ $0.first })
    /// // [Optional("o"): 1, Optional("t"): 2, nil: 4]
    /// ```
    ///
    /// - Parameters:
    ///   - transform: A closure that accepts each key of the dictionary as
    ///   its parameter and returns a transformed key of the same or of a different type.
    /// - Returns: A dictionary containing the transformed keys and values of this dictionary.
    func mapKeys<T>(_ transform: (Key) throws -> T) rethrows -> [T: Value] {
        try .init(map { (try transform($0.key), $0.value) },
                  uniquingKeysWith: { (a, b) in a })
    }
    
    /// Transforms dictionary keys without modifying values.
    /// Deduplicates transformed keys.
    ///
    /// Example:
    /// ```
    /// ["one": 1, "two": 2, "three": 3, "": 4].mapKeys({ $0.first }, uniquingKeysWith: { max($0, $1) })
    /// // [Optional("o"): 1, Optional("t"): 3, nil: 4]
    /// ```
    /// Credits:  https://forums.swift.org/t/mapping-dictionary-keys/15342/4
    ///
    /// - Parameters:
    ///   - transform: A closure that accepts each key of the dictionary as
    ///   its parameter and returns a transformed key of the same or of a different type.
    ///   - combine:A closure that is called with the values for any duplicate
    ///   keys that are encountered. The closure returns the desired value for
    ///   the final dictionary.
    /// - Returns: A dictionary containing the transformed keys and values of this dictionary.
    func mapKeys<T>(_ transform: (Key) throws -> T, uniquingKeysWith combine: (Value, Value) throws -> Value) rethrows -> [T: Value] {
          try .init(map { (try transform($0.key), $0.value) }, uniquingKeysWith: combine)
      }
}
