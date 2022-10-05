//
//  MigrationManager.swift
//  LeanplumSDK
//
//  Created by Nikola Zagorchev on 13.07.22.
//

import Foundation

@objc public class MigrationManager: NSObject {
    
    private override init() {
        super.init()
    }
    
    @objc public static let shared: MigrationManager = .init()
    
    var wrapper: CTWrapper? = nil
    
    @StringOptionalUserDefaults(key: Constants.HashKey)
    var migrationHash: String?
    
    @StringOptionalUserDefaults(key: Constants.AccountIdKey)
    //@objc private(set)
    var accountId: String?
    
    @StringOptionalUserDefaults(key: Constants.AccountTokenKey)
    //@objc private(set)
    var accountToken: String?
    
    @StringOptionalUserDefaults(key: Constants.RegionCodeKey)
    //@objc private(set)
    var regionCode: String?
    
    @PropUserDefaults(key: Constants.AttributeMappingsKey, defaultValue: [:])
    //@objc private(set)
    var attributeMappings: [String: String]
    
    @MigrationStateUserDefaults(key: Constants.HashKey, defaultValue: .undefined)
    @objc
    public
    //private(set)
    var migrationState: MigrationState {
        didSet {
            if oldValue != migrationState {
                handleMigrationStateChanged(oldValue: oldValue)
            }
        }
    }
    
    // Expose to ObjC
    @objc public var useLeanplum: Bool {
        migrationState.useLeanplum
    }
    
    // Expose to ObjC
    @objc public var useCleverTap: Bool {
        migrationState.useCleverTap
    }
    
    private let lock = NSLock()
    
    func initWrapper() {
        if migrationState.useCleverTap {
            guard let id = accountId, let token = accountToken, let accountRegion = regionCode else {
                Log.error("Missing CleverTap Credentials. Cannot initialize CleverTap.")
                return
            }
            guard let user = Leanplum.userId(), let device = Leanplum.deviceId() else {
                Log.error("Missing Leanplum userId and deviceId. Cannot initialize CleverTap.")
                return
            }

            wrapper = CTWrapper(accountId: id, accountToken: token,
                                accountRegion: accountRegion,
                                userId: user, deviceId: device)
            
            if Leanplum.hasStarted() {
                Log.debug("Leanplum has already started, launching CleverTap as well.")
                wrapper?.launch()
            }
        }
    }
    
    func handleMigrationStateChanged(oldValue: MigrationState) {
        // Note: It is not possible to return from CT only state since status comes from LP API
        
        if (!oldValue.useCleverTap && migrationState.useCleverTap) {
            // Flush all saved requests to Leanplum
            LPRequestSender.sharedInstance().sendRequests()
            // Create wrapper
            initWrapper()
        }
        
        if (oldValue.useLeanplum && !migrationState.useLeanplum) {
            LPOperationQueue.serialQueue().addOperation {
                // Flush all saved data to LP
                LPRequestSender.sharedInstance().sendRequests()
                // Delete LP data
                VarCache.shared().clearUserContent()
                VarCache.shared().saveDiffs()
            }
        }
        
        if (oldValue.useCleverTap && !migrationState.useCleverTap) {
            // Remove wrapper
            wrapper = nil
        }
    }
    
    
    // onMigrationStateLoaded
    
    @objc public func fetchMigrationState(_ completion: @escaping ()->()) {
        if migrationState != .undefined {
            initWrapper()
            completion()
            return
        }
        
        fetchMigrationStateClosures.append(completion)
    }
    
    var fetchMigrationStateClosures:[(() -> Void)] = [] {
        willSet {
            lock.lock()
        }
        didSet {
            defer {
                lock.unlock()
            }
            if oldValue.isEmpty && fetchMigrationStateClosures.count > 0 {
                fetchMigrationStateAsync { [weak self] in
                    NSLog("[MigrationLog] triggerOnMigrationStateLoaded")
                    self?.triggerFetchMigrationState()
                }
            }
        }
    }
    
    private func triggerFetchMigrationState() {
        let closures = fetchMigrationStateClosures
        fetchMigrationStateClosures = []
        for closure in closures {
            closure()
        }
    }
    
    func fetchMigrationStateAsync(completion: @escaping ()->()) {
        let request = LPRequestFactory.getMigrateState()
        request.requestType = .Immediate
        request.onResponse { operation, response in
            Log.debug("[MigrationLog] getMigrateState success: \(response ?? "")")
            
            guard let response = response else {
                Log.error("[MigrationLog] No response received for getMigrateState")
                return
            }
            
            self.handleGetMigrateState(apiResponse: response)
            completion()
        }
        
        request.onError { err in
            Log.error("[MigrationLog] Error getting migrate state")
            completion()
        }
        LPRequestSender.sharedInstance().send(request)
    }
}

@objc public extension MigrationManager {
    
    @objc func launch() {
        wrapper?.launch()
    }
    
    @objc func track(_ eventName: String?, value: Double, info: String?, params: [String: Any]) {
        wrapper?.track(eventName, value: value, info: info, params: params)
    }
    
    @objc func trackPurchase(_ eventName: String?, value: Double, currencyCode: String?, params: [String: Any]) {
        wrapper?.trackPurchase(eventName, value: value, currencyCode: currencyCode, params: params)
    }
    
    @objc func trackInAppPurchase(_ eventName: String?, value: Double, currencyCode: String?,
                            iOSTransactionIdentifier: String?, iOSReceiptData: String?,
                                  iOSSandbox: Bool, params: [String: Any]) {
        wrapper?.trackInAppPurchase(eventName, value: value, currencyCode: currencyCode, iOSTransactionIdentifier: iOSTransactionIdentifier, iOSReceiptData: iOSReceiptData, iOSSandbox: iOSSandbox, params: params)
    }
    
    @objc func advance(_ eventName: String?, info: String?, params: [String: Any]) {
        wrapper?.advance(eventName, info: info, params: params)
    }
    
    func setUserAttributes(_ attributes: [AnyHashable: Any]) {
        wrapper?.setUserAttributes(attributes)
    }
    
    func setUserId(_ userId: String) {
        wrapper?.setUserId(userId)
    }
    
    func setDeviceId(_ deviceId: String) {
        wrapper?.setDeviceId(deviceId)
    }
    
    func getProfileID() {
        wrapper?.cleverTapInstance?.profileGetID()
    }
    
    func setLogLevel(_ level: LeanplumLogLevel) {
        wrapper?.setLogLevel(level)
    }
}
