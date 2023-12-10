//
//  IdentityManagerMocks.swift
//  LeanplumSDKTests
//
//  Created by Nikola Zagorchev on 7.10.22.
//

import Foundation
@testable import Leanplum

class IdentityManagerMock: IdentityManager {
    var _anonymousLoginUserId: String?
    override var anonymousLoginUserId: String? {
        get {
            return _anonymousLoginUserId
        }
        set {
            _anonymousLoginUserId = newValue
        }
    }
    
    var _state: String?
    override var state: String? {
        get {
            return _state
        }
        set {
            _state = newValue
        }
    }
}

class IdentityManagerMockStatic: IdentityManager {
    static var _anonymousLoginUserId: String?
    override var anonymousLoginUserId: String? {
        get {
            return IdentityManagerMockStatic._anonymousLoginUserId
        }
        set {
            IdentityManagerMockStatic._anonymousLoginUserId = newValue
        }
    }
    
    static var _state: String?
    override var state: String? {
        get {
            return IdentityManagerMockStatic._state
        }
        set {
            IdentityManagerMockStatic._state = newValue
        }
    }
    
    init(userId: String, deviceId: String, anonymousLoginUserId: String?, state: String?, loggedInUserId: String? = nil) {
        // Needs to be set before call to super.init
        IdentityManagerMockStatic._anonymousLoginUserId = anonymousLoginUserId
        IdentityManagerMockStatic._state = state
        
        super.init(userId: userId, deviceId: deviceId, loggedInUserId: loggedInUserId)
    }
}
