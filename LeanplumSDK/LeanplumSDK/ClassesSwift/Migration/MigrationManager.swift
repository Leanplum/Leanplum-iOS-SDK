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
    
    @objc public var useMigrationJson = false
    
    public func migrationState(didChanged notification: NSNotification) {
        let intState = notification.userInfo?["migrationStatus"] as? Int
        if let intState = intState, let value = MigrationStatus(rawValue: intState) {
            switch value {
            case .undefined, .leanplum:
                wrapper = nil
            case .duplicate, .cleverTap:
                guard let id = accountId, let token = accountToken else {
                    // TODO: log keys not present cannot init wrapper
                    return
                }

                wrapper = CTWrapper(accountId: id, accountToken: token, migrationStatus: value)
                if Leanplum.hasStarted() {
                    wrapper?.launch()
                }
            }
        }
    }
    
//    public func migrationState(didChangedToValue value: MigrationStatus) {
//        switch value {
//        case .undefined, .leanplum:
//            wrapper = nil
//        case .duplicate, .cleverTap:
//            guard let id = accountId, let token = accountToken else {
//                // TODO: log keys not present cannot init wrapper
//                return
//            }
//
//            wrapper = CTWrapper(accountId: id, accountToken: token, migrationStatus: value)
//        }
//    }
    
    deinit {
        removeObserver(self)
    }
    
    @objc public static let shared: MigrationManager = .init()
    
    var wrapper: CTWrapper? = nil    
    
//    let observers = AtomicDictionary<UUID, MigrationStateObserver>()
//    let _observers = AtomicDictionary<UUID, ((MigrationStatusInt) -> Void)>()
    
    
    enum Constants {
        static let AccountIdKey = "__leanplum_ct_account_key"
        static let AccountTokenKey = "__leanplum_ct_account_token"
        static let MigrationStateKey = "__leanplum_migration_state"
        
        static let GetMigrationStateTimeout = 2.0
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
    
    private(set) var migrationState: MigrationStatus {
        get {
            if let savedState = UserDefaults.standard.string(forKey: Constants.MigrationStateKey) {
                _migrationState = MigrationStatus.init(stringValue: savedState)
                return _migrationState
            }
            return .undefined
        }
        set {
            if migrationState != newValue {
                UserDefaults.standard.setValue(newValue.rawValue, forKey: Constants.MigrationStateKey)
                _migrationState = newValue
            }
        }
    }
    
    private let lock = NSLock()
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
        let request = LPRequestFactory.getMigrationState([:])
        request.requestType = .Immediate
        request.onResponse { operation, response in
            print("[MigrationLog] success")
            
            self.migrationState = .leanplum
            completion()
        }
        
        request.onError { err in
            print("[MigrationLog] error")
            
            self.migrationState = .leanplum
            completion()
        }
        LPRequestSender.sharedInstance().send(request)
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
        NotificationCenter.default.post(name: .migrationStateChanged, object: self, userInfo: ["migrationStatus": value.rawValue])
    }
}

@objc public extension MigrationManager {
    
    @objc func updateMigrationStatus(apiResponse: Any) {
        
        if let state = getValue(dict: apiResponse, key: "migrationState"),
           let id = getValue(dict: state, key: "accountId") as? String {
            accountId = id
        }
        
        if let state = getValue(dict: apiResponse, key: "migrationState"),
           let token = getValue(dict: state, key: "accountToken") as? String {
            accountToken = token
        }
        
        if let state = getValue(dict: apiResponse, key: "migrationState"),
           let traffic = getValue(dict: state, key: "traffic"),
           let sdk = getValue(dict: traffic, key: "sdk") as? String {
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
}
