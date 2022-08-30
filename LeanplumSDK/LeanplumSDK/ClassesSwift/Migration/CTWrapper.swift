//
//  CTWrapper.swift
//  LeanplumSDK
//
//  Created by Nikola Zagorchev on 9.07.22.
//

import Foundation
import CleverTapSDK

public class CTWrapper {
    
    
    // TODO: value > 0 -> config?
    // TODO: info -> config?
    // TODO: value and info names capitalized?
    
    // TODO: check if CT needs to be initialized with identity if userId != deviceId
    // TODO: check app launched event when ct is initialized mid-session
    
    
    // TODO: or static methods which call instance method and instance is controlled by status didSet
    
    // TODO: launch CT if status changes mid session
    
    // TODO: migration status change can most probably happen on app background when request is sent
    
    enum Constants {
        static let Identity = "Identity"
        static let StatePrefix = "state_"
        static let ValueParamName = "value"
        static let InfoParamName = "info"
    }
    
    // TODO: get instance properly
//    lazy var cleverTapInstance: CleverTap = {
//        let config = CleverTapInstanceConfig.init(accountId: accountId, accountToken: accountToken)
//        var instance: CleverTap
//        if let cleverTapID = cleverTapID {
//            instance = CleverTap.instance(with: config, andCleverTapID: cleverTapID)
//        } else {
//            instance = CleverTap.instance(with: config)
//        }
//        instance.setLibrary("Leanplum")
//        return instance
//    }()
    
    var cleverTapInstance: CleverTap?
    
    
    var status: MigrationManager.MigrationStatus
    var accountId: String
    var accountToken: String
    
    // MARK: Initialization
    public init(accountId: String, accountToken: String, migrationStatus: MigrationManager.MigrationStatus) {
        status = migrationStatus
        self.accountId = accountId
        self.accountToken = accountToken
    }
    
    func launch() {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [self] in
                launch()
            }
            return
        }
        
        // TODO: can we check if already initialized with custom clever tap id before?
        let config = CleverTapInstanceConfig.init(accountId: accountId, accountToken: accountToken)
        config.useCustomCleverTapId = true
        if let cleverTapID = cleverTapID {
            cleverTapInstance = CleverTap.instance(with: config, andCleverTapID: cleverTapID)
        } else {
            cleverTapInstance = CleverTap.instance(with: config)
        }
        cleverTapInstance!.setLibrary("Leanplum")
//
//        CleverTap.sharedInstance(withCleverTapID: <#T##String#>)
//        CleverTap.setCredentialsWithAccountID("", andToken: "")
//        CleverTap.sharedInstance()?.setLibrary("Leanplum")
//
//        CleverTap.autoIntegrate(withCleverTapID: cleverTapID!)
        
        //CleverTap.sharedInstance()?.notifyApplicationLaunched(withOptions: nil)
    }

    // MARK: Events
    func track(_ eventName: String?, value: Double, info: String?, args: [String: Any], params: [String: Any]) {
        
        // message impression events come with event: nil
        guard let eventName = eventName else {
            return
        }
    
        var eventParams = params
        // TODO: disregard value == 0.0 ?
        if value != 0 {
            eventParams[Constants.ValueParamName] = value
        }
        
        if let info = info {
            eventParams[Constants.InfoParamName] = info
        }
        
        if isPurchase(args: args) {
            // copy arguments to params
            // keep original value in params if key exists
            eventParams.merge(args){ (current, _) in current }
            // TODO: if is purchase use recordChargedEvent?
        }

        cleverTapInstance?.recordEvent(eventName, withProps: eventParams)
    }
    
    func advance(_ stateName: String?, info: String?, params: [String: Any]) {
        guard let stateName = stateName else {
            return
        }
        
        let eventName = Constants.StatePrefix + stateName
        track(eventName, value: 0.0, info: info, args: [:], params: params)
    }
    
    func setUserAttributes(_ attributes: [AnyHashable: Any]) {
        cleverTapInstance?.profilePush(attributes)
    }
    
    func isPurchase(args: [String: Any]) -> Bool {
        return args[LP_PARAM_CURRENCY_CODE] != nil
    }
    
    
    // MARK: Identity
    
    public func setDeviceId(_ deviceId: String) {
        // Precondition: deviceId is already set and preserved in LP
        guard let cleverTapID = cleverTapID else { return }
        
        var identity = deviceId
        if let userId = Leanplum.userId() {
            identity = userId
        }
        
        cleverTapInstance?.onUserLogin([Constants.Identity: identity], withCleverTapID: cleverTapID)
    }
    
    public func setUserId(_ userId: String) {
        
        // TODO: if both id is changed and attrbiutes passed - set the attributes in the onUserLogin map?
        
        // Precondition: userId is already set and preserved in LP
        guard let cleverTapID = cleverTapID else { return }
        cleverTapInstance?.onUserLogin([Constants.Identity: userId], withCleverTapID: cleverTapID)
    }
    
    var cleverTapID: String? {
        guard let deviceId = Leanplum.deviceId() else {
            return nil
        }
        
        if let userId = Leanplum.userId(),
            userId != deviceId {
            return "\(deviceId)_\(userId)"
        }
        
        return deviceId
    }
    
}
