//
//  IdentityManagerTest.swift
//  LeanplumSDKTests
//
//  Created by Nikola Zagorchev on 7.10.22.
//

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
        
        XCTAssertFalse(identityManager.isAnonymous)
        XCTAssertEqual(identityManager.state, IdentityManager.IdentityState.identified())
        XCTAssertEqual(identityManager.cleverTapID, "deviceId_userId")
    }
    
    func testIdentifiedNewUser() {
        let identityManager = IdentityManagerMock(userId: "userId", deviceId: "deviceId")
        
        identityManager.setUserId("userId2")
        
        XCTAssertFalse(identityManager.isAnonymous)
        XCTAssertEqual(identityManager.state, IdentityManager.IdentityState.identified())
        XCTAssertEqual(identityManager.anonymousLoginUserId, nil)
        XCTAssertEqual(identityManager.cleverTapID, "deviceId_userId2")
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
        
        XCTAssertFalse(identityManager.isAnonymous)
        XCTAssertEqual(identityManager.state, IdentityManager.IdentityState.identified())
        XCTAssertEqual(identityManager.anonymousLoginUserId, "userId")
        XCTAssertEqual(identityManager.cleverTapID, "deviceId_userId2")
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
}
