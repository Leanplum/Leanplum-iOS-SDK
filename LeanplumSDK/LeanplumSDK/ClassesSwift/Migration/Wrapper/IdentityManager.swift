//
//  IdentityManager.swift
//  LeanplumSDK
//
//  Created by Nikola Zagorchev on 6.10.22.
//  Copyright © 2022 Leanplum. All rights reserved.

import Foundation
// Use @_implementationOnly to *not* expose CleverTapSDK to the Leanplum-Swift header
@_implementationOnly import CleverTapSDK

/**
 * Identity mapping between Leanplum userId and deviceId and CleverTap Identity and CTID.
 *
 *  Mappings:
 *  - anonymous: <CTID=deviceId, Identity=null>
 *  - non-anonymous to <CTID=deviceId_userIdHash, Identity=userId>
 *  - if invalid deviceId <deviceId=deviceIdHash>
 *
 *  UserId Hash is generated using the first 10 chars of the userId SHA256 string (hex).
 *  If the deviceId does _not_ pass validation _or_ is _longer_ than 50 characters,
 *  the first 32 chars of the deviceId SHA256 string (hex) are used as deviceIdHash.
 *
 *  - Note: On login of anonymous user, a merge should happen. CleverTap SDK allows merges
 *  only when the CTID remains the same, meaning that the merged profile would get the anonymous
 *  profile's CTID: <CTID=deviceId, Identity=userIdHash>.
 *  In order to keep track which is that userId, it is saved into `anonymousLoginUserId`.
 *  For this userId, the CTID is always set to deviceId.
 *  Leanplum UserId can be set through Leanplum.start and Leanplum.setUserId
 *
 * - Precondition: DeviceId cannot be changed when CT is used,
 *  since CTID cannot be modified for the same Identity.
*/
class IdentityManager {
    enum Constants {
        static let Identity = "Identity"
        static let AnonymousLoginUserIdKey = "__leanplum_anonymous_login_user_id"
        static let IdentityStateKey = "__leanplum_identity_state"
        
        static let DeviceIdLengthLimit = 50
        static let IdentityHashLength = 10
    }
    
    enum IdentityState: String  {
        case anonymous = "anonymous"
        case identified = "identified"
        
        func callAsFunction() -> String {
            return self.rawValue
        }
    }
    
    private(set) var userId: String
    private(set) var deviceId: String
    
    @StringOptionalUserDefaults(key: Constants.AnonymousLoginUserIdKey)
    var anonymousLoginUserId: String?
    
    @StringOptionalUserDefaults(key: Constants.IdentityStateKey)
    var state: String?
    
    @StringOptionalUserDefaults(key: "loggedInUserId")
    var loggedInUserId: String?
    
    convenience init(userId: String, deviceId: String) {
        self.init(userId: userId, deviceId: deviceId, loggedInUserId: nil)
    }
    
    init(userId: String, deviceId: String, loggedInUserId: String?) {
        self.userId = userId
        self.deviceId = deviceId
        self.loggedInUserId = loggedInUserId
        
        identify()
    }
    
    func setUserId(_ userId: String) {
        if userId == deviceId && state == IdentityState.identified() {
            return
        }
        
        if state == IdentityState.anonymous() {
            if let hash = Utilities.sha256_40(string: userId) {
                anonymousLoginUserId = hash
            } else {
                Log.error("[Wrapper] Failed to generate SHA256 for userId: \(userId)")
                anonymousLoginUserId = userIdHash
            }
            Log.debug("[Wrapper] Anonymous user on device \(deviceId) will be merged to \(userId)")
            state = IdentityState.identified()
        }
        self.userId = userId
    }
    
    func identify() {
        if isAnonymous, let loggedInUserId = self.loggedInUserId {
            self.userId = loggedInUserId
            state = IdentityState.identified()
        } else if isAnonymous {
            state = IdentityState.anonymous()
        } else {
            identifyNonAnonymous()
        }
    }
    
    func identifyNonAnonymous() {
        if let state = state,
           state == IdentityState.anonymous() {
            anonymousLoginUserId = userIdHash
        }
        state = IdentityState.identified()
    }
    
    var userIdHash: String {
        guard let hash = Utilities.sha256_40(string: userId) else {
            Log.error("[Wrapper] Failed to generate SHA256 for userId: \(userId)")
            return userId
        }

        return hash
    }

    var isValidCleverTapID: Bool {
        // Only the deviceId could be invalid, since the userIdHash should always be valid
        CleverTap.isValidCleverTapId(deviceId) &&
        deviceId.count <= Constants.DeviceIdLengthLimit
    }
    
    var originalCleverTapID: String {
        if shouldAppendUserId {
            return "\(deviceId)_\(userIdHash)"
        }
        
        return deviceId
    }

    var cleverTapID: String {
        if isValidCleverTapID {
            return originalCleverTapID
        }
        
        guard let ctDevice = Utilities.sha256_200(string: deviceId) else {
            Log.error("[Wrapper] Failed to generate SHA256 for deviceId: \(deviceId)")
            return originalCleverTapID
        }
        
        if shouldAppendUserId {
            return "\(ctDevice)_\(userIdHash)"
        }
        
        return ctDevice
    }
    
    var profile: [AnyHashable: Any] {
        [Constants.Identity: userId]
    }
    
    var isAnonymous: Bool {
        userId == deviceId
    }
    
    var shouldAppendUserId: Bool {
        userIdHash != anonymousLoginUserId && userId != deviceId
    }
}
