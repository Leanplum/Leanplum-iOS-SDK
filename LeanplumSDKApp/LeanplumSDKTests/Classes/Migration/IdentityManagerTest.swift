//
//  IdentityManagerTest.swift
//  LeanplumSDKTests
//
//  Created by Nikola Zagorchev on 7.10.22.
//  Copyright © 2023 Leanplum. All rights reserved.

import Foundation
import XCTest
@testable import Leanplum

class IdentityManagerTest: XCTestCase {
    
    let userId = "userId"
    let deviceId = "deviceId"
    
    let userId2 = "userId2"
    
    // 6ccb21214ffd60b0fc2c1607cf6a05be6a0fed9c74819eb6a92e1bd6717b28eb
    let userId_hash = "6ccb21214f"
    // c9430313f85740d3c62dd8bf8c8d275165e96f830e7b1e6ddf3a89ba17ee5cce
    let userId2_hash = "c9430313f8"
    
    let deviceId_hash = "5e51fbb1d8"
    
    let totalIdLengthLimit = 61
    let deviceIdHashLength = 50
    
    func assertUserIdIdentified(_ identityManager: IdentityManager, _ userId_hash: String, _ anonymousLoginUserId: String? = nil) {
        XCTAssertFalse(identityManager.isAnonymous)
        XCTAssertEqual(identityManager.anonymousLoginUserId, anonymousLoginUserId)
        XCTAssertEqual(identityManager.state, IdentityManager.IdentityState.identified())
        XCTAssertEqual(identityManager.cleverTapID, "\(deviceId)_\(userId_hash)")
    }
    
    func testProfile() {
        let identityManager = IdentityManagerMock(userId: deviceId, deviceId: deviceId)
        
        let identityManagerUser = IdentityManagerMock(userId: userId, deviceId: deviceId)
        
        XCTAssertTrue(identityManager.profile.isEqual(["Identity": deviceId]))
        XCTAssertTrue(identityManagerUser.profile.isEqual(["Identity": userId]))
    }
    
    func testUserIdHash() {
        let identityManager = IdentityManagerMock(userId: "some-user-id", deviceId: deviceId)
        XCTAssertTrue(identityManager.userIdHash.count == 10)
    }
    
    func testUserIdHashSha() {
        let identityManager = IdentityManagerMock(userId: userId, deviceId: deviceId)
        XCTAssertEqual(identityManager.userIdHash, userId_hash)
    }
    
    func testUserIdHashWithSha() {
        let userId = "9d29641dc261454239456122f13de042b3a0cc3f45d4c27e7ddc97b300eb11aa"
        let identityManager = IdentityManagerMock(userId: userId, deviceId: deviceId)
        let sha = Utilities.sha256(string: userId)!
        let index = sha.index(sha.startIndex, offsetBy: 10)
        let expected = String(sha[..<index])
        XCTAssertEqual(identityManager.userIdHash, expected)
    }
    
    func testAnonymous() {
        let identityManager = IdentityManagerMock(userId: deviceId, deviceId: deviceId)
        
        XCTAssertTrue(identityManager.isAnonymous)
        XCTAssertEqual(identityManager.state, IdentityManager.IdentityState.anonymous())
        XCTAssertEqual(identityManager.cleverTapID, deviceId)
    }
    
    func testAnonymousAndLoggedInUser() {
        let identityManager = IdentityManagerMock(userId: deviceId, deviceId: deviceId, loggedInUserId: userId)
        
        assertUserIdIdentified(identityManager, userId_hash)
    }
    
    func testUserAndLoggedInUser() {
        let identityManager = IdentityManagerMock(userId: userId, deviceId: deviceId, loggedInUserId: userId)
        
        assertUserIdIdentified(identityManager, userId_hash)
    }
    
    func testLoggedInUserLoginBack() {
        let identityManager = IdentityManagerMock(userId: deviceId, deviceId: deviceId, loggedInUserId: userId)
        
        assertUserIdIdentified(identityManager, userId_hash)
        
        identityManager.setUserId(userId2)
        
        assertUserIdIdentified(identityManager, userId2_hash)
        
        identityManager.setUserId(userId)
        
        assertUserIdIdentified(identityManager, userId_hash)
    }
    
    func testLoggedInUserLoginAgainUser() {
        let identityManager = IdentityManagerMock(userId: deviceId, deviceId: deviceId, loggedInUserId: userId)
        
        assertUserIdIdentified(identityManager, userId_hash)
        
        identityManager.setUserId(userId)
        
        assertUserIdIdentified(identityManager, userId_hash)
        
        identityManager.setUserId(userId2)
        
        assertUserIdIdentified(identityManager, userId2_hash)
    }
    
    func testLoggedInUserUserIdAlreadySet() {
        let identityManager = IdentityManagerMock(userId: userId, deviceId: deviceId, loggedInUserId: userId)
        
        assertUserIdIdentified(identityManager, userId_hash)
        
        identityManager.setUserId(userId)
        
        assertUserIdIdentified(identityManager, userId_hash)
        
        identityManager.setUserId(userId2)
        
        assertUserIdIdentified(identityManager, userId2_hash)
        
        identityManager.setUserId(userId)
        
        assertUserIdIdentified(identityManager, userId_hash)
    }
    
    func testLoggedInUserSetDeviceIdAsUserId() {
        let identityManager = IdentityManagerMock(userId: deviceId, deviceId: deviceId, loggedInUserId: userId)
        
        assertUserIdIdentified(identityManager, userId_hash)
        
        identityManager.setUserId(deviceId)
        
        assertUserIdIdentified(identityManager, deviceId_hash)

        identityManager.setUserId(userId)
        
        assertUserIdIdentified(identityManager, userId_hash)
        
        identityManager.setUserId(userId2)
        
        assertUserIdIdentified(identityManager, userId2_hash)
    }
    
    func testLoggedInUserDeviceId() {
        let identityManager = IdentityManagerMock(userId: deviceId, deviceId: deviceId, loggedInUserId: deviceId)
        
        assertUserIdIdentified(identityManager, deviceId_hash)
        
        // Set again the deviceId as userId
        identityManager.setUserId(deviceId)
        
        assertUserIdIdentified(identityManager, deviceId_hash)

        // Set a new user Id
        identityManager.setUserId(userId)
        
        assertUserIdIdentified(identityManager, userId_hash)
        
        // Set another new user Id
        identityManager.setUserId(userId2)
        
        assertUserIdIdentified(identityManager, userId2_hash)
    }
    
    func testIdentified() {
        let identityManager = IdentityManagerMock(userId: userId, deviceId: deviceId)
        
        assertUserIdIdentified(identityManager, userId_hash)
    }
    
    func testIdentifiedNewUser() {
        let identityManager = IdentityManagerMock(userId: userId, deviceId: deviceId)
        
        identityManager.setUserId(userId2)
        
        assertUserIdIdentified(identityManager, userId2_hash)
    }
    
    func testAnonymousLogin() {
        let identityManager = IdentityManagerMock(userId: deviceId, deviceId: deviceId)
        
        identityManager.setUserId(userId)
        
        XCTAssertFalse(identityManager.isAnonymous)
        XCTAssertEqual(identityManager.state, IdentityManager.IdentityState.identified())
        XCTAssertEqual(identityManager.anonymousLoginUserId, userId_hash)
        XCTAssertEqual(identityManager.cleverTapID, deviceId)
    }
    
    func testAnonymousLoginDeviceId() {
        let identityManager = IdentityManagerMock(userId: deviceId, deviceId: deviceId)
        // isAnonymous is true since userId=deviceId
        XCTAssertTrue(identityManager.isAnonymous)
        
        // Since is anonymous and set userId equals deviceId, this should be NOOP
        identityManager.setUserId(deviceId)
        
        // isAnonymous is true since userId=deviceId
        XCTAssertTrue(identityManager.isAnonymous)
        // state is still anonymous
        XCTAssertEqual(identityManager.state, IdentityManager.IdentityState.anonymous())
        XCTAssertEqual(identityManager.anonymousLoginUserId, nil)
        XCTAssertEqual(identityManager.cleverTapID, deviceId)
        
        identityManager.setUserId(userId)
        
        XCTAssertFalse(identityManager.isAnonymous)
        XCTAssertEqual(identityManager.state, IdentityManager.IdentityState.identified())
        XCTAssertEqual(identityManager.anonymousLoginUserId, userId_hash)
        XCTAssertEqual(identityManager.cleverTapID, deviceId)
    }
    
    func testIdentifiedLoginDeviceId() {
        let identityManager = IdentityManagerMock(userId: deviceId, deviceId: deviceId)
        // isAnonymous is true since userId=deviceId
        XCTAssertTrue(identityManager.isAnonymous)
        
        // Login a user
        identityManager.setUserId(userId)
        XCTAssertFalse(identityManager.isAnonymous)
        XCTAssertEqual(identityManager.state, IdentityManager.IdentityState.identified())
        XCTAssertEqual(identityManager.anonymousLoginUserId, userId_hash)
        XCTAssertEqual(identityManager.cleverTapID, deviceId)
        
        // Login with deviceId. Since is not anonymous, create a new profile
        identityManager.setUserId(deviceId)
        assertUserIdIdentified(identityManager, deviceId_hash, userId_hash)
    }
    
    func testAnonymousLoginNewUser() {
        let identityManager = IdentityManagerMock(userId: deviceId, deviceId: deviceId)
        
        identityManager.setUserId(userId)
        
        identityManager.setUserId(userId2)
        
        assertUserIdIdentified(identityManager, userId2_hash, userId_hash)
    }
    
    func testAnonymousLoginBack() {
        let identityManager = IdentityManagerMock(userId: deviceId, deviceId: deviceId)
        
        identityManager.setUserId(userId)
        
        identityManager.setUserId(userId2)
        
        identityManager.setUserId(userId)
        
        XCTAssertFalse(identityManager.isAnonymous)
        XCTAssertEqual(identityManager.state, IdentityManager.IdentityState.identified())
        XCTAssertEqual(identityManager.cleverTapID, deviceId)
    }
    
    func testAnonymousLoginStart() {
        let initialIdentityManager = IdentityManagerMock(userId: deviceId, deviceId: deviceId)
        
        let identityManager = IdentityManagerMockStatic(userId: userId, deviceId: initialIdentityManager.deviceId, anonymousLoginUserId: initialIdentityManager.anonymousLoginUserId, state: initialIdentityManager.state)
        
        XCTAssertFalse(identityManager.isAnonymous)
        XCTAssertEqual(identityManager.state, IdentityManager.IdentityState.identified())
        XCTAssertEqual(identityManager.anonymousLoginUserId, userId_hash)
        XCTAssertEqual(identityManager.cleverTapID, deviceId)
    }
    
    func testAnonymousLimitDeviceId() {
        let deviceId = Array(repeating: "1", count: deviceIdHashLength).joined()
        let identityManager = IdentityManagerMock(userId: deviceId, deviceId: deviceId)
        
        XCTAssertEqual(identityManager.cleverTapID, deviceId)
        XCTAssertTrue(identityManager.cleverTapID.count <= totalIdLengthLimit)
    }
    
    func testIdentifiedLimitDeviceId() {
        let deviceId = Array(repeating: "1", count: deviceIdHashLength).joined()
        let identityManager = IdentityManagerMock(userId: userId, deviceId: deviceId)
        
        XCTAssertEqual(identityManager.cleverTapID, "\(deviceId)_\(userId_hash)")
        XCTAssertTrue(identityManager.cleverTapID.count == totalIdLengthLimit)
    }
    
    func testAnonymousLongDeviceId() {
        let deviceId = Array(repeating: "1", count: deviceIdHashLength + 1).joined()
        let identityManager = IdentityManagerMock(userId: deviceId, deviceId: deviceId)
        
        let deviceId_sha = Utilities.sha256_200(string: deviceId)!
        
        XCTAssertEqual(identityManager.cleverTapID, deviceId_sha)
        XCTAssertTrue(identityManager.cleverTapID.count == deviceIdHashLength)
        XCTAssertTrue(identityManager.cleverTapID.count <= totalIdLengthLimit)
    }
    
    func testIdentifiedLongDeviceId() {
        let deviceId = Array(repeating: "1", count: deviceIdHashLength + 1).joined()
        let identityManager = IdentityManagerMock(userId: userId, deviceId: deviceId)
        
        let deviceId_sha = Utilities.sha256_200(string: deviceId)!
        
        XCTAssertEqual(identityManager.cleverTapID, "\(deviceId_sha)_\(userId_hash)")
        XCTAssertTrue(identityManager.cleverTapID.count == totalIdLengthLimit)
    }
    
    func testIdentifiedLongerDeviceId() {
        let deviceId = Array(repeating: "1", count: deviceIdHashLength + 10).joined()
        let identityManager = IdentityManagerMock(userId: userId, deviceId: deviceId)
        
        let deviceId_sha = Utilities.sha256_200(string: deviceId)!
        
        XCTAssertEqual(identityManager.cleverTapID, "\(deviceId_sha)_\(userId_hash)")
        XCTAssertTrue(identityManager.cleverTapID.count == totalIdLengthLimit)
    }
    
    func testAnonymousInvalidDeviceId() {
        let deviceId = Array(repeating: "&", count: 10).joined()
        let identityManager = IdentityManagerMock(userId: deviceId, deviceId: deviceId)
        
        let deviceId_sha = Utilities.sha256_200(string: deviceId)!
        
        XCTAssertEqual(identityManager.cleverTapID, deviceId_sha)
        XCTAssertTrue(identityManager.cleverTapID.count <= totalIdLengthLimit)
    }
    
    func testIdentifiedInvalidDeviceId() {
        let deviceId = Array(repeating: "&", count: 10).joined()
        let identityManager = IdentityManagerMock(userId: userId, deviceId: deviceId)
        
        let deviceId_sha = Utilities.sha256_200(string: deviceId)!
        
        XCTAssertEqual(identityManager.cleverTapID, "\(deviceId_sha)_\(userId_hash)")
        XCTAssertTrue(identityManager.cleverTapID.count <= totalIdLengthLimit)
    }
    
    func testIdentifiedEmailUserId() {
        let userId = "test@test.com"
        let identityManager = IdentityManagerMock(userId: userId, deviceId: deviceId)

        // f660ab912ec121d1b1e928a0bb4bc61b15f5ad44d5efdc4e1c92a25e99b8e44a
        let userId_sha = "f660ab912e"

        XCTAssertEqual(identityManager.cleverTapID, "\(deviceId)_\(userId_sha)")
        XCTAssertTrue(identityManager.cleverTapID.count <= totalIdLengthLimit)
    }
    
    func testInvalidUserIds() {
        let invalidDeviceIds = [
            // -\:\"fcea8952-0ae1-411d-b23c-50661050ded1\"
            #"-\:\"fcea8952-0ae1-411d-b23c-50661050ded1\""#,
            // abd6039873\",4562412546555904
            #"abd6039873\",4562412546555904"#,
            // !22113163828\""
            #"!22113163828\"""#,
            // "22121327322\",4562412546555904
            // 117669683\""
            #"""
            "22121327322\",4562412546555904"
            117669683\""
            """#,
            // 117669683\""
            #"117669683\"""#,
            "嘁脂Ήᔠ䦐ࠐ䤰†",
            "{{device.hardware_id}}",
            "116115935'2",
            "9d29641dc261454239456122f13de042b3a0cc3f45d4c27e7ddc97b300eb11aa"
        ]
        
        let hashes = invalidDeviceIds.map(Utilities.sha256_200(string:))
        
        for (i, id) in invalidDeviceIds.enumerated() {
            let identityManager = IdentityManagerMock(userId: userId, deviceId: id)
            print("\(i) -> \(id)")
            print(hashes[i]!)
            print(identityManager.cleverTapID)
            XCTAssertEqual(identityManager.cleverTapID, "\(hashes[i]!)_\(userId_hash)")
            XCTAssertTrue(identityManager.cleverTapID.count <= totalIdLengthLimit)
        }
    }
}
