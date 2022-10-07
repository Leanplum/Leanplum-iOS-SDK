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
    
    var wrapper: Wrapper?
    
    @StringOptionalUserDefaults(key: Constants.HashKey)
    var migrationHash: String?
    
    @StringOptionalUserDefaults(key: Constants.AccountIdKey)
    var accountId: String?
    
    @StringOptionalUserDefaults(key: Constants.AccountTokenKey)
    var accountToken: String?
    
    @StringOptionalUserDefaults(key: Constants.RegionCodeKey)
    var regionCode: String?
    
    @PropUserDefaults(key: Constants.AttributeMappingsKey, defaultValue: [:])
    var attributeMappings: [String: String]
    
    @MigrationStateUserDefaults(key: Constants.HashKey, defaultValue: .undefined)
    var migrationState: MigrationState {
        didSet {
            if oldValue != migrationState {
                handleMigrationStateChanged(oldValue: oldValue)
            }
        }
    }
    
    private let lock = NSLock()
    
    var instanceCallback: ((Any) -> Void)? {
        didSet {
            wrapper?.setInstanceCallback(instanceCallback)
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
    
    func initWrapper() {
        if migrationState.useCleverTap {
            guard let id = accountId, let token = accountToken, let accountRegion = regionCode else {
                Log.error("[Wrapper] Missing CleverTap Credentials. Cannot initialize CleverTap.")
                return
            }
            guard let user = Leanplum.userId(), let device = Leanplum.deviceId() else {
                Log.error("[Wrapper] Missing Leanplum userId and deviceId. Cannot initialize CleverTap.")
                return
            }

            wrapper = CTWrapper(accountId: id, accountToken: token,
                                accountRegion: accountRegion,
                                userId: user, deviceId: device,
                                callback: instanceCallback)
            
            if Leanplum.hasStarted() {
                Log.debug("[Wrapper] Leanplum has already started, launching CleverTap as well.")
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
            guard let response = response else {
                Log.error("[Wrapper] No response received for getMigrateState")
                return
            }
            
            Log.debug("[Wrapper] getMigrateState success: \(response)")
            self.handleGetMigrateState(apiResponse: response)
            completion()
        }
        
        request.onError { err in
            Log.error("[Wrapper] Error on getMigrateState: \(err?.localizedDescription ?? "nil")")
            completion()
        }
        LPRequestSender.sharedInstance().send(request)
    }
}
