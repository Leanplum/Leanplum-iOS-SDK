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
    
    // TODO: reset varcache when ct only but persist userId, deviceId, token
    
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
            // TODO: fix optionals
            wrapper = CTWrapper(accountId: id, accountToken: token, accountRegion: accountRegion, userId: Leanplum.userId()!, deviceId: Leanplum.deviceId()!)
            
            if Leanplum.hasStarted() {
                wrapper?.launch()
            }
        }
    }
    
    func handleMigrationStateChanged(oldValue: MigrationState) {
        // TODO: not possible to go from CT only back to LP or LP+CT right now, since status comes from LP API
        
        if (!oldValue.useCleverTap && migrationState.useCleverTap) {
            LPOperationQueue.serialQueue().addOperation { [self] in
                // Flush all saved requests to Leanplum
                LPRequestSender.sharedInstance().sendRequests()
                // Create wrapper
                initWrapper()
            }
        }
        
        if (oldValue.useLeanplum && !migrationState.useLeanplum) {
            LPOperationQueue.serialQueue().addOperation {
                // flush all saved data to LP
                LPRequestSender.sharedInstance().sendRequests()
                // delete LP data
                VarCache.shared().clearUserContent()
                VarCache.shared().saveDiffs()
            }
        }
        
        if (oldValue.useCleverTap && !migrationState.useCleverTap) {
            // remove wrapper
            wrapper = nil
        }
    }
    
    
    // onMigrationStateLoaded
    
    @objc public func onMigrationStateLoaded(completion: @escaping ()->()) {
        if migrationState != .undefined {
            initWrapper()
            completion()
            return
        }
        
        onMigrationStateLoadedBlocks.append(completion)
    }
    
    var onMigrationStateLoadedBlocks:[(() -> Void)] = [] {
        willSet {
            lock.lock()
        }
        didSet {
            defer {
                lock.unlock()
            }
            if oldValue.isEmpty && onMigrationStateLoadedBlocks.count > 0 {
                fetchMigrationStateAsync { [weak self] in
                    NSLog("[MigrationLog] triggerOnMigrationStateLoaded")
                    self?.triggerOnMigrationStateLoaded()
                }
            }
        }
    }
    
    private func triggerOnMigrationStateLoaded() {
        let blocks = onMigrationStateLoadedBlocks
        onMigrationStateLoadedBlocks = []
        for block in blocks {
            block()
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
    
    @objc func start() {
        wrapper?.launch()
    }
    
    @objc func track(_ eventName: String?, value: Double, info: String?, args: [String: Any], params: [String: Any]) {
        wrapper?.track(eventName, value: value, info: info, args: args, params: params)
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
}
