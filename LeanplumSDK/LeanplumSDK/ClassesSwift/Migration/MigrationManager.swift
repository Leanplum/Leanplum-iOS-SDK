//
//  MigrationManager.swift
//  LeanplumSDK
//
//  Created by Nikola Zagorchev on 13.07.22.
//

import Foundation

@objc public class MigrationManager: NSObject, MigrationStateObserver {
    private override init() {
        super.init()
        addObserver(self)
    }
    
    // TODO: reset varcache when ct only but persist userId, deviceId, token
    
    enum Constants {
        static let AccountIdKey = "__leanplum_ct_account_key"
        static let AccountTokenKey = "__leanplum_ct_account_token"
        static let MigrationStateKey = "__leanplum_migration_state"
        
        static let MigrateStateResponseParam = "migrateState"
        static let MigrateStateNotificationInfo = "migrateState"
        static let SdkResponseParam = "sdk"
        static let CTResponseParam = "ct"
        static let AccountIdResponseParam = "accountId"
        static let AccountTokenResponseParam = "token"
        
        static let CleverTapParam = "ct"
    }
    
    @objc
    public class func lpMigrateStateNotificationInfo() -> String {
        return Constants.MigrateStateNotificationInfo
    }
    
    @objc
    public class func lpCleverTapParam() -> String {
        return Constants.CleverTapParam
    }
    
    private let lock = NSLock()
    
    @objc public static let shared: MigrationManager = .init()
    
    var wrapper: CTWrapper? = nil
    
    @objc private(set) var accountId: String? {
        get {
            if let accountId = UserDefaults.standard.string(forKey: Constants.AccountIdKey) {
                return accountId
            }
            return nil
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: Constants.AccountIdKey)
        }
    }
    
    @objc private(set) var accountToken: String? {
        get {
            if let accountToken = UserDefaults.standard.string(forKey: Constants.AccountTokenKey) {
                return accountToken
            }
            return nil
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: Constants.AccountTokenKey)
        }
    }
    
    private var _migrationState: MigrationStatus = .undefined {
        didSet {
            if oldValue != _migrationState {
                notifyObservers(value: _migrationState)
            }
        }
    }
    
    public private(set) var migrationState: MigrationStatus {
        get {
            if let savedState = UserDefaults.standard.string(forKey: Constants.MigrationStateKey) {
                _migrationState = MigrationStatus.init(stringValue: savedState)
                return _migrationState
            }
            return .undefined
        }
        set {
            if migrationState != newValue {
                UserDefaults.standard.setValue(newValue.description, forKey: Constants.MigrationStateKey)
                _migrationState = newValue
            }
        }
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
                fetchMigrationState { [weak self] in
                    NSLog("[MigrationLog] triggerOnMigrationStateLoaded")
                    self?.triggerOnMigrationStateLoaded()
                }
            }
        }
    }
    
    @objc public enum MigrationStatus: Int, CustomStringConvertible, CaseIterable {
        
        case undefined = 0,
             leanplum,
             duplicate,
             cleverTap
        
        public var description: String {
            switch self {
            case .undefined:
                return "undefined"
            case .leanplum:
                return "lp"
            case .duplicate:
                return "lp+ct"
            case .cleverTap:
                return "ct"
            }
        }
        
        public init(stringValue: String) {
            let value = Self.allCases.first {
                $0.description == stringValue
            }
            self = value ?? .undefined
        }
    }
    
    public func migrationState(didChanged notification: NSNotification) {
        let intState = notification.userInfo?[Constants.MigrateStateNotificationInfo] as? Int
        if let intState = intState, let value = MigrationStatus(rawValue: intState) {
            switch value {
            case .undefined, .leanplum:
                wrapper = nil
            case .duplicate, .cleverTap:
                guard let id = accountId, let token = accountToken else {
                    Log.error("Missing CleverTap Account Id and Account Token. Cannot initialize CleverTap.")
                    return
                }
                wrapper = CTWrapper(accountId: id, accountToken: token, migrationStatus: value)
                if Leanplum.hasStarted() {
                    wrapper?.launch()
                }
            }
        }
    }
    
    func triggerOnMigrationStateLoaded() {
        let blocks = onMigrationStateLoadedBlocks
        onMigrationStateLoadedBlocks = []
        for block in blocks {
            block()
        }
    }
    
    @objc public func onMigrationStateLoaded(completion: @escaping ()->()) {
        if migrationState != .undefined {
            completion()
            return
        }
        
        onMigrationStateLoadedBlocks.append(completion)
    }
    
    func fetchMigrationState(completion: @escaping ()->()) {
        let request = LPRequestFactory.getMigrateState()
        request.requestType = .Immediate
        request.onResponse { operation, response in
            Log.info("[MigrationLog] getMigrateState success: \(response ?? "")")
            
            guard let response = response else {
                Log.error("[MigrationLog] No response received for getMigrateState")
                return
            }
            
            self.updateMigrationStatus(apiResponse: response)
            completion()
        }
        
        request.onError { err in
            Log.error("[MigrationLog] Error getting migrate state")
            completion()
        }
        LPRequestSender.sharedInstance().send(request)
    }
    
    deinit {
        removeObserver(self)
    }
}

@objc public protocol MigrationStateObserver {
    @objc(migrationStateDidChanged:)
    func migrationState(didChanged notification: NSNotification)
}

fileprivate extension Notification.Name {
    static var migrationStateChanged: Notification.Name {
        return .init(rawValue: "\(MigrationManager.self).\(#function)")
    }
}

@objc extension MigrationManager {
    @discardableResult
    @objc public func addObserver(_ observer: MigrationStateObserver) -> MigrationStatus {
        NotificationCenter.default.addObserver(observer, selector: #selector(observer.migrationState(didChanged:)), name: .migrationStateChanged, object: self)
        return .undefined
    }
    
    @objc public func removeObserver(_ observer: MigrationStateObserver) {
        NotificationCenter.default.removeObserver(observer, name: .migrationStateChanged, object: self)
    }
    
    func notifyObservers(value: MigrationStatus) {
        NotificationCenter.default.post(name: .migrationStateChanged, object: self, userInfo: [Constants.MigrateStateNotificationInfo: value.rawValue])
    }
}

@objc public extension MigrationManager {
//    {
//        migrateState =     {
//            ct =         {
//                accountId = id;
//                regionCode = eu;
//                token = token;
//            };
//            sdk = "lp+ct";
//        };
//    }
    @objc func updateMigrationStatus(multiApiResponse: Any) {
        guard let migrateState = getValue(dict: multiApiResponse, key: Constants.MigrateStateResponseParam) else { return }
        
        updateMigrationStatus(apiResponse: migrateState)
    }
    
    @objc func updateMigrationStatus(apiResponse: Any) {
        if let ct = getValue(dict: apiResponse, key: Constants.CTResponseParam) {
            if let id = getValue(dict: ct, key: Constants.AccountIdResponseParam) as? String {
                accountId = id
            }
            
            if let token = getValue(dict: ct, key: Constants.AccountTokenResponseParam) as? String {
                accountToken = token
            }
        }
        
        if let sdk = getValue(dict: apiResponse, key: Constants.SdkResponseParam) as? String {
            migrationState = MigrationStatus(stringValue: sdk)
        }
    }
    
    private func getValue(dict: Any, key: String) -> Any? {
        guard let dict = dict as? [String: Any] else {
            return nil
        }
        
        return dict[key]
    }
}

@objc public extension MigrationManager {
    
    @objc func start() {
        wrapper?.launch()
    }
    
    @objc func track(_ eventName: String?, value: Double, info: String?, args: [String: Any], params: [String: Any]) {
        wrapper?.track(eventName, value: value, info: info, args: args, params: params)
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
