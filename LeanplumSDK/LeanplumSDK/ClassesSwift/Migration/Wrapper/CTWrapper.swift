//
//  CTWrapper.swift
//  LeanplumSDK
//
//  Created by Nikola Zagorchev on 9.07.22.
//  Copyright © 2023 Leanplum. All rights reserved.

import Foundation
// Use @_implementationOnly to *not* expose CleverTapSDK to the Leanplum-Swift header
@_implementationOnly import CleverTapSDK

class CTWrapper: Wrapper {
    // MARK: Constants
    enum Constants {
        static let StatePrefix = "state_"
        
        static let ValueParamName = "value"
        static let ChargedEventParam = "event"
        static let CurrencyCodeParam = "currencyCode"
        static let iOSTransactionIdentifierParam = "iOSTransactionIdentifier"
        static let iOSReceiptDataParam = "iOSReceiptData"
        static let iOSSandboxParam = "iOSSandbox"
        
        static let DevicesUserProperty = "lp_devices"
        static let AnonymousDeviceUserProperty = "lp_device"
    }
    
    // MARK: Initialization
    var cleverTapInstance: CleverTap?
    var instanceCallbacks: [CleverTapInstanceCallback]
    
    var accountId: String
    var accountToken: String
    var accountRegion: String
    var identityManager: IdentityManager
    
    var useCustomCleverTapId: Bool
    
    public init(accountId: String,
                accountToken: String,
                accountRegion: String,
                useCustomCleverTapId: Bool,
                userId: String,
                deviceId: String,
                loggedInUserId: String?,
                callbacks: [CleverTapInstanceCallback]) {
        Log.info("[Wrapper] Wrapper Instantiated")
        self.accountId = accountId
        self.accountToken = accountToken
        self.accountRegion = accountRegion
        self.instanceCallbacks = callbacks
        self.useCustomCleverTapId = useCustomCleverTapId
        
        identityManager = IdentityManager(userId: userId, deviceId: deviceId, loggedInUserId: loggedInUserId)
        setLogLevel(LPLogManager.logLevel())
    }
    
    func onUserLogin() {
        if useCustomCleverTapId {
            cleverTapInstance?.onUserLogin(identityManager.profile,
                                           withCleverTapID: identityManager.cleverTapID)
        } else {
            cleverTapInstance?.onUserLogin(identityManager.profile)
        }
    }
    
    func launch() {
        let config = CleverTapInstanceConfig.init(accountId: accountId, accountToken: accountToken, accountRegion: accountRegion)
        config.identityKeys = MigrationManager.shared.identityKeys
        config.logLevel = CleverTapLogLevel(LPLogManager.logLevel())
        
        if useCustomCleverTapId {
            config.useCustomCleverTapId = true
            cleverTapInstance = CleverTap.instance(with: config, andCleverTapID: identityManager.cleverTapID)
        } else {
            cleverTapInstance = CleverTap.instance(with: config)
        }

        cleverTapInstance?.setLibrary("Leanplum")
        // Track App Launched
        cleverTapInstance?.notifyApplicationLaunched(withOptions: [:])
        Log.debug("[Wrapper] CleverTap instance created with accountId: \(accountId)")
        // Set the current push token registered in Leanplum
        setCurrentPushToken()
        
        if !identityManager.isAnonymous {
            Log.debug("""
                    [Wrapper] will call onUserLogin with \
                    Identity: \(identityManager.userId) and cleverTapId: \(identityManager.cleverTapID)"
                    """)
            onUserLogin()
            setDevicesProperty()
        } else {
            if !identityManager.isValidCleverTapID {
                cleverTapInstance?.profilePush([Constants.AnonymousDeviceUserProperty: identityManager.deviceId])
            }
        }
        triggerInstanceCallbacks()
    }
    
    var hasLaunched: Bool {
        return cleverTapInstance != nil
    }
    
    // MARK: Callback
    func addInstanceCallback(_ callback: CleverTapInstanceCallback) {
        instanceCallbacks.append(callback)
        if let instance = cleverTapInstance {
            callback.onInstance(instance)
        }
    }
    
    func removeInstanceCallback(_ callback: CleverTapInstanceCallback) {
        guard let index = instanceCallbacks.firstIndex(of: callback) else { return }
        instanceCallbacks.remove(at: index)
    }
    
    private func triggerInstanceCallbacks() {
        guard let instance = cleverTapInstance else { return }
        
        for callback in instanceCallbacks {
            callback.onInstance(instance)
        }
    }

    // MARK: Tracking
    func track(_ eventName: String?, value: Double, params: [String: Any]) {
        // message impression events come with event: nil
        // do not track Push Delivered in CT
        guard let eventName = eventName, eventName != PUSH_DELIVERED_EVENT_NAME else {
            return
        }
    
        var eventParams = params.mapValues(transformArrayValues)
        eventParams[Constants.ValueParamName] = value

        Log.debug("Leanplum.track will call recordEvent with \(eventName) and \(eventParams)")
        cleverTapInstance?.recordEvent(eventName, withProps: eventParams)
    }
    
    func advance(_ stateName: String?, params: [String: Any]) {
        guard let stateName = stateName else {
            return
        }
        
        let eventName = Constants.StatePrefix + stateName
        Log.debug("Leanplum.advance will call track with \(eventName) and \(params)")
        track(eventName, value: 0.0, params: params)
    }
    
    func trackPurchase(_ eventName: String?, value: Double, currencyCode: String?, params: [String: Any]) {
        guard let eventName = eventName else {
            return
        }
    
        var details = params.mapValues(transformArrayValues)
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
        var details = params.mapValues(transformArrayValues)
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
            .mapValues(transformArrayValues)
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
        onUserLogin()
        
        setDevicesProperty()
    }
    
    func setPushToken(_ token: Data) {
        Log.debug("[Wrapper] Calling CleverTap.setPushToken")
        cleverTapInstance?.setPushToken(token)
    }
    
    func setCurrentPushToken() {
        if let token = Leanplum.user.pushToken {
            Log.debug("[Wrapper] Setting current push token using setPushTokenAs")
            cleverTapInstance?.setPushTokenAs(token)
        }
    }
    
    func setDevicesProperty() {
        // CleverTap SDK ensures the values are unique locally
        if !identityManager.isValidCleverTapID {
            cleverTapInstance?.profileAddMultiValue(identityManager.deviceId, forKey: Constants.DevicesUserProperty)
        }
    }
    
    // MARK: Traffic Source
    func setTrafficSourceInfo(_ info: [AnyHashable: Any]) {
        let source = info["publisherName"] as? String
        let medium = info["publisherSubPublisher"] as? String
        let campaign = info["publisherSubCampaign"] as? String
        
        Log.debug("""
                [Wrapper] Leanplum.setTrafficSourceInfo will call pushInstallReferrerSource \
                with \(source ?? "null"), \(medium ?? "null") and \(campaign ?? "null")
                """)
        cleverTapInstance?.pushInstallReferrerSource(source, medium: medium, campaign: campaign)
    }
    
    // MARK: Log Level
    func setLogLevel(_ level: LeanplumLogLevel) {
        let ctLevel = CleverTapLogLevel(level)
        CleverTap.setDebugLevel(ctLevel.rawValue)
        cleverTapInstance?.config.logLevel = ctLevel
    }
}
