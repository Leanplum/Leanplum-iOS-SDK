//
//  CTWrapper.swift
//  LeanplumSDK
//
//  Created by Nikola Zagorchev on 9.07.22.
//

import Foundation
// Use @_implementationOnly to *not* expose CleverTapSDK to the Leanplum-Swift header
@_implementationOnly import CleverTapSDK

public class CTWrapper {
    enum Constants {
        static let Identity = "Identity"
        
        static let StatePrefix = "state_"
        static let ValueParamName = "value"
        static let InfoParamName = "info"
        static let ChargedEventParam = "event"
        static let CurrencyCodeParam = "currencyCode"
        static let iOSTransactionIdentifierParam = "iOSTransactionIdentifier"
        static let iOSReceiptDataParam = "iOSReceiptData"
        static let iOSSandboxParam = "iOSSandbox"
        
        static let FirstLoginUserIdKey = "__leanplum_lp_first_user_id"
        static let FirstLoginDeviceIdKey = "__leanplum_lp_first_device_id"
    }
    
    var cleverTapInstance: CleverTap?
    
    var accountId: String
    var accountToken: String
    var accountRegion: String
    var userId: String
    var deviceId: String
    
    @StringOptionalUserDefaults(key: Constants.FirstLoginUserIdKey)
    var firstLoginUserId: String?
    
    @StringOptionalUserDefaults(key: Constants.FirstLoginDeviceIdKey)
    var firstLoginDeviceId: String?
    
    // MARK: Initialization
    public init(accountId: String, accountToken: String, accountRegion: String, userId: String, deviceId: String) {
        Log.debug("Wrapper: Wrapper Instantiated")
        self.accountId = accountId
        self.accountToken = accountToken
        self.accountRegion = accountRegion
        self.userId = userId
        self.deviceId = deviceId
        
        setLogLevel(LPLogManager.logLevel())
    }
    
    var cleverTapID: String {
        if !isAnonymous, userId != firstLoginUserId {
            return "\(deviceId)_\(userId)"
        }
        
        if userId == firstLoginUserId,
        let firstDeviceId = firstLoginDeviceId {
            return firstDeviceId
        }
            
        return deviceId
    }
    
    var isAnonymous: Bool {
        userId == deviceId
    }
    
    public func getInstance() -> Any? {
        return cleverTapInstance
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
        cleverTapInstance = CleverTap.instance(with: config, andCleverTapID: cleverTapID)
        cleverTapInstance?.setLibrary("Leanplum")
        
        Log.debug("Wrapper: CleverTap instance created with accountId: \(accountId) and accountToken: \(accountToken)")
        //CleverTap.sharedInstance()?.notifyApplicationLaunched(withOptions: nil)
        
        if !isAnonymous {
            Log.debug("Wrapper: will call onUserLogin with identity: \(userId) and cleverTapId: \(cleverTapID)")
            cleverTapInstance?.onUserLogin([Constants.Identity: userId],
                                           withCleverTapID: cleverTapID)
        }
        triggerInstanceCallback()
    }
    
    func triggerInstanceCallback() {
        // TODO: implement callback
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

    func isPurchase(args: [String: Any]) -> Bool {
        return args[LP_PARAM_CURRENCY_CODE] != nil
    }
    
    
    // MARK: Identity
    
    public func setDeviceId(_ deviceId: String) {
        self.deviceId = deviceId
        let identity = deviceId != userId ? userId : deviceId

        Log.debug("""
                  Wrapper: Leanplum.setDeviceId will call onUserLogin \
                  with identity: \(identity) and CleverTapID: \(cleverTapID)
                """)
        cleverTapInstance?.onUserLogin([Constants.Identity: identity],
                                       withCleverTapID: cleverTapID)
    }
    
    public func setUserId(_ userId: String) {
        guard userId != self.userId else { return }
        
        let anon = isAnonymous
        self.userId = userId
        
        if anon {
            firstLoginUserId = userId
            firstLoginDeviceId = deviceId
            Log.debug("Wrapper: anonymous user on device \(deviceId) will be merged to \(userId)")
        }
        
        Log.debug("""
                Wrapper: Leanplum.setUserId will call onUserLogin with identity: \(userId) and CleverTapID:  \(cleverTapID)")
                """)
        cleverTapInstance?.onUserLogin([Constants.Identity: userId], withCleverTapID: cleverTapID)
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
