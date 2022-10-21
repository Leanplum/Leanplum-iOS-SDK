//
//  IdentityManagerTest.swift
//  LeanplumSDKTests
//
//  Created by Nikola Zagorchev on 7.10.22.
//  Copyright © 2022 Leanplum. All rights reserved.

import Foundation
import XCTest
@testable import Leanplum

class IdentityManagerTest: XCTestCase {
    
    func testProfile() {
        let identityManager = IdentityManagerMock(userId: "deviceId", deviceId: "deviceId")
        
        let identityManagerUser = IdentityManagerMock(userId: "userId", deviceId: "deviceId")
        
        XCTAssertTrue(identityManager.profile.isEqual(["Identity": "deviceId"]))
        XCTAssertTrue(identityManagerUser.profile.isEqual(["Identity": "userId"]))
    }
    
    func testAnonymous() {
        let identityManager = IdentityManagerMock(userId: "deviceId", deviceId: "deviceId")
        
        XCTAssertTrue(identityManager.isAnonymous)
        XCTAssertEqual(identityManager.state, IdentityManager.IdentityState.anonymous())
        XCTAssertEqual(identityManager.cleverTapID, "deviceId")
    }
    
    func testIdentified() {
        let identityManager = IdentityManagerMock(userId: "userId", deviceId: "deviceId")
        
        let userId_sha = "6ccb21214f"
        
        XCTAssertFalse(identityManager.isAnonymous)
        XCTAssertEqual(identityManager.state, IdentityManager.IdentityState.identified())
        XCTAssertEqual(identityManager.cleverTapID, "deviceId_\(userId_sha)")
    }
    
    func testIdentifiedNewUser() {
        let identityManager = IdentityManagerMock(userId: "userId", deviceId: "deviceId")
        
        identityManager.setUserId("userId2")
        let userId2_sha = "c9430313f8"
        
        XCTAssertFalse(identityManager.isAnonymous)
        XCTAssertEqual(identityManager.state, IdentityManager.IdentityState.identified())
        XCTAssertEqual(identityManager.anonymousLoginUserId, nil)
        XCTAssertEqual(identityManager.cleverTapID, "deviceId_\(userId2_sha)")
    }
    
    func testAnonymousLogin() {
        let identityManager = IdentityManagerMock(userId: "deviceId", deviceId: "deviceId")
        
        identityManager.setUserId("userId")
        
        XCTAssertFalse(identityManager.isAnonymous)
        XCTAssertEqual(identityManager.state, IdentityManager.IdentityState.identified())
        XCTAssertEqual(identityManager.anonymousLoginUserId, "userId")
        XCTAssertEqual(identityManager.cleverTapID, "deviceId")
    }
    
    func testAnonymousLoginNewUser() {
        let identityManager = IdentityManagerMock(userId: "deviceId", deviceId: "deviceId")
        
        identityManager.setUserId("userId")
        
        identityManager.setUserId("userId2")
        let userId2_sha = "c9430313f8"
        
        XCTAssertFalse(identityManager.isAnonymous)
        XCTAssertEqual(identityManager.state, IdentityManager.IdentityState.identified())
        XCTAssertEqual(identityManager.anonymousLoginUserId, "userId")
        XCTAssertEqual(identityManager.cleverTapID, "deviceId_\(userId2_sha)")
    }
    
    func testAnonymousLoginBack() {
        let identityManager = IdentityManagerMock(userId: "deviceId", deviceId: "deviceId")
        
        identityManager.setUserId("userId")
        
        identityManager.setUserId("userId2")
        
        identityManager.setUserId("userId")
        
        XCTAssertFalse(identityManager.isAnonymous)
        XCTAssertEqual(identityManager.state, IdentityManager.IdentityState.identified())
        XCTAssertEqual(identityManager.cleverTapID, "deviceId")
    }
    
    func testAnonymousLoginStart() {
        let initialIdentityManager = IdentityManagerMock(userId: "deviceId", deviceId: "deviceId")
        
        let identityManager = IdentityManagerMockStatic(userId: "userId", deviceId: initialIdentityManager.deviceId, anonymousLoginUserId: initialIdentityManager.anonymousLoginUserId, state: initialIdentityManager.state)
        
        XCTAssertFalse(identityManager.isAnonymous)
        XCTAssertEqual(identityManager.state, IdentityManager.IdentityState.identified())
        XCTAssertEqual(identityManager.anonymousLoginUserId, "userId")
        XCTAssertEqual(identityManager.cleverTapID, "deviceId")
    }
    
    func testIdentifiedLimitDeviceId() {
        let deviceId = Array(repeating: "1", count: 50).joined()
        let identityManager = IdentityManagerMock(userId: "userId", deviceId: deviceId)
        
        let userId_sha = "6ccb21214f"
        
        XCTAssertEqual(identityManager.cleverTapID, "\(deviceId)_\(userId_sha)")
    }
    
    func testIdentifiedLongDeviceId() {
        let deviceId = Array(repeating: "1", count: 51).joined()
        let identityManager = IdentityManagerMock(userId: "userId", deviceId: deviceId)
        
        let userId_sha = "6ccb21214f"
        let deviceId_sha = "c383f53b5708fc0975ba1ac052c650c0"
        
        XCTAssertEqual(identityManager.cleverTapID, "\(deviceId_sha)_\(userId_sha)")
    }
    
    func testIdentifiedLongerDeviceId() {
        let deviceId = Array(repeating: "1", count: 60).joined()
        let identityManager = IdentityManagerMock(userId: "userId", deviceId: deviceId)
        
        let userId_sha = "6ccb21214f"
        let deviceId_sha = "70d36dedb311176c76ecd7f78d72340d"
        
        XCTAssertEqual(identityManager.cleverTapID, "\(deviceId_sha)_\(userId_sha)")
    }
    
    func testIdentifiedInvalidDeviceId() {
        let deviceId = Array(repeating: "&", count: 10).joined()
        let identityManager = IdentityManagerMock(userId: "userId", deviceId: deviceId)
        
        let userId_sha = "6ccb21214f"
        let deviceId_sha = "595b6f123778a4903ea51b67b2aaac9e"
        
        XCTAssertEqual(identityManager.cleverTapID, "\(deviceId_sha)_\(userId_sha)")
    }
}
