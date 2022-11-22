//
//  MigrationManager.swift
//  LeanplumSDK
//
//  Created by Nikola Zagorchev on 13.07.22.
//  Copyright © 2022 Leanplum. All rights reserved.

import Foundation

@objc public class MigrationManager: NSObject {
    
    private override init() {
        super.init()
    }
    
    @objc public static let shared: MigrationManager = .init()
    
    var wrapper: Wrapper?
    var instanceCallbacks: [CleverTapInstanceCallback] = []
    
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
    
    @MigrationStateUserDefaults(key: Constants.MigrationStateKey, defaultValue: .undefined)
    var migrationState: MigrationState {
        didSet {
            if oldValue != migrationState {
                handleMigrationStateChanged(oldValue: oldValue)
            }
        }
    }
    
    private let lock = NSLock()
    
    @objc public func launchWrapper() {
        if migrationState.useCleverTap, wrapper == nil {
            guard let id = accountId, let token = accountToken, let accountRegion = regionCode else {
                Log.error("[Wrapper] Missing CleverTap Credentials. Cannot initialize CleverTap.")
                return
            }
            
            if !LPInternalState.shared().calledStart {
                Log.info("[Wrapper] Initializing before calling start. Loading user.")
                loadUser()
            }

            guard let user = Leanplum.user.userId, let device = Leanplum.user.deviceId else {
                Log.error("[Wrapper] Missing Leanplum userId and deviceId. Cannot initialize CleverTap.")
                return
            }

            wrapper = CTWrapper(accountId: id, accountToken: token,
                                accountRegion: accountRegion,
                                userId: user, deviceId: device,
                                callbacks: instanceCallbacks)
            wrapper?.launch()
        }
    }
    
    func loadUser() {
        guard let encryptedDiffs = UserDefaults.standard.data(forKey: LEANPLUM_DEFAULTS_VARIABLES_KEY),
              let diffsData = LPAES.decryptedData(from: encryptedDiffs) else { return }
        
        var unarchiver: NSKeyedUnarchiver?
        
        if #available(iOS 11.0, *) {
            do {
                unarchiver = try NSKeyedUnarchiver(forReadingFrom: diffsData)
            } catch {
                Log.error("[Wrapper] Error unarchiving userId and deviceId.")
            }
        } else {
            unarchiver = NSKeyedUnarchiver(forReadingWith: diffsData)
        }

        unarchiver?.requiresSecureCoding = false
        
        Leanplum.user.deviceId = unarchiver?.decodeObject(forKey: LP_PARAM_DEVICE_ID) as? String
        
        Leanplum.user.userId = unarchiver?.decodeObject(forKey: LP_PARAM_USER_ID) as? String
    }
    
    func handleMigrationStateChanged(oldValue: MigrationState) {
        // Note: It is not possible to return from CT only state since status comes from LP API
        
        if (!oldValue.useCleverTap && migrationState.useCleverTap) {
            // Flush all saved requests to Leanplum
            LPRequestSender.sharedInstance().sendRequests()
            // Create wrapper
            launchWrapper()
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
            launchWrapper()
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
