//
//  IdentityManager.swift
//  LeanplumSDK
//
//  Created by Nikola Zagorchev on 6.10.22.
//  Copyright © 2022 Leanplum. All rights reserved.

import Foundation
// Use @_implementationOnly to *not* expose CleverTapSDK to the Leanplum-Swift header
@_implementationOnly import CleverTapSDK

// TODO: fix description
/**
 * Identity mapping between Leanplum userId and deviceId and CleverTap Identity and CTID.
 *
 *  Mappings:
 *  - anonymous: <CTID=deviceId, Identity=null>
 *  - non-anonymous to <CTID=deviceId_userId, Identity=userId>
 *
 *  - Note: On login of anonymous user, a merge should happen. CleverTap SDK allows merges
 *  only when the CTID remains the same, meaning that the merged profile would get the anonymous
 *  profile's CTID: <CTID=deviceId, Identity=userId>.
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
        
        static let CTIDLengthLimit = 50
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
    
    init(userId: String, deviceId: String) {
        self.userId = userId
        self.deviceId = deviceId
        
        identify()
    }
    
    func setUserId(_ userId: String) {
        if (state == IdentityState.anonymous()) {
            anonymousLoginUserId = userId
            Log.debug("[Wrapper] Anonymous user on device \(deviceId) will be merged to \(userId)")
            state = IdentityState.identified()
        }
        self.userId = userId
    }
    
    func identify() {
        if isAnonymous {
            state = IdentityState.anonymous()
        } else {
            identifyNonAnonymous()
        }
    }
    
    func identifyNonAnonymous() {
        if let state = state,
           state == IdentityState.anonymous() {
            anonymousLoginUserId = userId
        }
        state = IdentityState.identified()
    }
    
    var identity: String {
        // TODO: handle errors
        guard let str = Utilities.sha256(string: userId) else { return userId }
        
        let endIndex = str.index(str.startIndex, offsetBy: Constants.IdentityHashLength)
        return String(str[..<endIndex])
    }
    
    var cleverTapID: String {
        if isValidCleverTapID {
            return originalCleverTapID
        }
        
        // TODO: handle errors
        let sha256_128 = Utilities.sha256_128(string: deviceId)!
        
        return "\(sha256_128)_\(identity)"
    }
    
    var isValidCleverTapID: Bool {
        CleverTap.isValidCleverTapId(originalCleverTapID) &&
        deviceId.count <= Constants.CTIDLengthLimit
    }
    
    var originalCleverTapID: String {
        if userId != anonymousLoginUserId,
           userId != deviceId {
            return "\(deviceId)_\(identity)"
        }
        
        return deviceId
    }
    
    var profile: [AnyHashable: Any] {
        [Constants.Identity: userId]
    }
    
    var isAnonymous: Bool {
        userId == deviceId
    }
}
