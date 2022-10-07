//
//  CTWrapper.swift
//  LeanplumSDK
//
//  Created by Nikola Zagorchev on 9.07.22.
//

import Foundation
// Use @_implementationOnly to *not* expose CleverTapSDK to the Leanplum-Swift header
@_implementationOnly import CleverTapSDK

class CTWrapper: Wrapper {
    // MARK: Constants
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
    
    // MARK: Initialization
    var cleverTapInstance: CleverTap?
    var instanceCallback: ((Any) -> Void)?
    
    var accountId: String
    var accountToken: String
    var accountRegion: String
    var identityManager: IdentityManager
    
    public init(accountId: String,
                accountToken: String,
                accountRegion: String,
                userId: String,
                deviceId: String,
                callback: ((Any) -> Void)?) {
        Log.debug("[Wrapper] Wrapper Instantiated")
        self.accountId = accountId
        self.accountToken = accountToken
        self.accountRegion = accountRegion
        self.instanceCallback = callback
        
        identityManager = IdentityManager(userId: userId, deviceId: deviceId)
        setLogLevel(LPLogManager.logLevel())
    }
    
    func launch() {
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
        
        Log.debug("[Wrapper] CleverTap instance created with accountId: \(accountId)")
        
        if !identityManager.isAnonymous {
            Log.debug("""
                    [Wrapper] will call onUserLogin with \
                    Identity: \(identityManager.userId) and cleverTapId: \(identityManager.cleverTapID)"
                    """)
            cleverTapInstance?.onUserLogin(identityManager.profile,
                                           withCleverTapID: identityManager.cleverTapID)
        }
        triggerInstanceCallback()
    }
    
    private func triggerInstanceCallback() {
        guard let callback = instanceCallback, let instance = cleverTapInstance else {
            return
        }
        
        callback(instance)
    }
    
    func setInstanceCallback(_ callback: ((Any) -> Void)?) {
        instanceCallback = callback
        triggerInstanceCallback()
    }

    // MARK: Tracking
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

        Log.debug("[Wrapper] Leanplum.trackPurchase will call recordChargedEvent with \(details) and \(items)")
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

        Log.debug("[Wrapper] Leanplum.trackInAppPurchase will call recordChargedEvent with \(details) and \(items)")
        cleverTapInstance?.recordChargedEvent(withDetails: details, andItems: items)
    }
    
    // MARK: User
    func setUserAttributes(_ attributes: [AnyHashable: Any]) {
        // .compactMapValues { $0 } will not work on not optional type Any which can still hold nil
        let profileAttributes = attributes
            .filter { !isAnyNil($0.value) }
            .mapValues(transformAttributeValues)
            .mapKeys(transformAttributeKeys)
        
        Log.debug("[Wrapper] Leanplum.setUserAttributes will call profilePush with \(profileAttributes)")
        cleverTapInstance?.profilePush(profileAttributes)
        
        attributes
            .filter { isAnyNil($0.value) }
            .mapKeys(transformAttributeKeys)
            .forEach {
                Log.debug("[Wrapper] Leanplum.setUserAttributes will call profileRemoveValue forKey: \($0.key)")
                cleverTapInstance?.profileRemoveValue(forKey: String(describing: $0.key))
            }
    }
    
    func setUserId(_ userId: String) {
        guard userId != identityManager.userId else { return }
        
        identityManager.setUserId(userId)
        
        let profile = identityManager.profile
        let cleverTapID = identityManager.cleverTapID
        
        Log.debug("""
                [Wrapper] Leanplum.setUserId will call onUserLogin \
                with identity: \(profile) \
                and CleverTapID:  \(cleverTapID)")
                """)
        cleverTapInstance?.onUserLogin(profile, withCleverTapID: cleverTapID)
    }
    
    // MARK: Traffic Source
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
        
        Log.debug("[Wrapper] Leanplum.setTrafficSourceInfo will call pushEvent with \(Constants.UTMVisitedEvent) and \(props)")
        cleverTapInstance?.recordEvent(Constants.UTMVisitedEvent, withProps: props)
    }
    
    // MARK: Log Level
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
