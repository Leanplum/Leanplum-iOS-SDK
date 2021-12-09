//
//  LeanplumNotificationsManagerUtilsTest.swift
//  LeanplumSDKTests
//
//  Created by Dejan Krstevski on 2.12.21.
//  Copyright © 2021 Leanplum. All rights reserved.
//

import Foundation

import XCTest
@testable import Leanplum

class LeanplumNotificationsManagerUtilsTest: XCTestCase {
    
    var manager: LeanplumNotificationsManager!
    
    override func setUp() {
        super.setUp()
        manager = LeanplumNotificationsManager()
    }
    
    override class func setUp() {
        super.setUp()
        LeanplumHelper.setup_development_test()
        LPAPIConfig.shared().deviceId = "testDeviceId"
        LPAPIConfig.shared().userId = "testUserId"
    }
    
    override class func tearDown() {
        LeanplumHelper.clean_up()
    }
    
    func setUp_request() {
        LPRequestFactory.swizzle_methods()
        LPRequestSender.swizzle_methods()
        LPInternalState.shared().hasStarted = true
        LPInternalState.shared().startSuccessful = true
    }
        
    func tearDown_request() {
        LPRequestSender.reset()
        LPRequestFactory.unswizzle_methods()
        LPRequestSender.unswizzle_methods()
        LPInternalState.shared().hasStarted = false
        LPInternalState.shared().startSuccessful = false
    }
    
    func testGetFormattedDeviceTokenFromData() {
        setUp_request()
        let tokenString = "testToken"
        let tokenData = tokenString.data(using: .utf8)
        let formattedToken = manager.getFormattedDeviceTokenFromData(tokenData!)
        
        let expectation = expectation(description: "Push token to server")
        LPRequestSender.validate_request { method, apiMethod, params in
            if apiMethod == LP_API_METHOD_SET_DEVICE_ATTRIBUTES {
                if let parameters = params, let token = parameters[LP_PARAM_DEVICE_PUSH_TOKEN] as? String {
                    XCTAssertEqual(formattedToken, token)
                    expectation.fulfill()
                    return true
                }
            }
            return false
        }
        
        manager.didRegisterForRemoteNotificationsWithDeviceToken(tokenData!)
        wait(for: [expectation], timeout: 5)
        tearDown_request()
    }
    
    func testPushToken() {
        //clean push token if any
        manager.removePushToken()
        XCTAssertNil(manager.pushToken())
        manager.updatePushToken("newToken")
        XCTAssertEqual(manager.pushToken(), "newToken")
    }
    
    func testDisableAskToAsk() {
        //clean user defaults
        UserDefaults.standard.removeObject(forKey: DEFAULTS_ASKED_TO_PUSH)
        XCTAssertFalse(manager.hasDisabledAskToAsk())
        manager.disableAskToAsk()
        XCTAssertTrue(manager.hasDisabledAskToAsk())
    }
    
    func testRefreshPushPermissions() {
        let managerMock = LeanplumNotificationsManagerMock.notificationsManager()
        XCTAssertEqual(managerMock.methodInvocations, 0)
        managerMock.enableSystemPush()
        XCTAssertEqual(managerMock.methodInvocations, 1)
        //refreshPushPermissions should call enableSystemPush
        managerMock.refreshPushPermissions()
        XCTAssertEqual(managerMock.methodInvocations, 2)
        LeanplumNotificationsManagerMock.reset()
    }
    
    func testNotificationSettingsToRequestParams() {
        var testSettings: [AnyHashable: Any] = [LP_PARAM_DEVICE_USER_NOTIFICATION_TYPES: 7,
                            LP_PARAM_DEVICE_USER_NOTIFICATION_CATEGORIES: []]
        var settigns = manager.notificationSettingsToRequestParams(testSettings)
        XCTAssertNotNil(settigns)
        testSettings = [:]
        settigns = manager.notificationSettingsToRequestParams(testSettings)
        XCTAssertNil(settigns)
    }
    
    func testRequireMessageContent() {
        setUp_request()
        let testMessageId = "1"
        VarCache.shared().applyVariableDiffs(nil, messages: nil, variants: nil, localCaps: nil, regions: nil, variantDebugInfo: nil, varsJson: nil, varsSignature: nil)
        
        let expectation = expectation(description: "Require Message Content")
        LPRequestSender.validate_request { method, apiMethod, params in
            if apiMethod == LP_API_METHOD_GET_VARS {
                if let parameters = params, let messageId = parameters[LP_PARAM_INCLUDE_MESSAGE_ID] as? String {
                    XCTAssertEqual(messageId, testMessageId)
                    expectation.fulfill()
                    return true
                }
            }
            return false
        }
        
        manager.requireMessageContentWithMessageId(testMessageId)
        
        wait(for: [expectation], timeout: 5)
        
        //cleanup
        VarCache.shared().reset()
        VarCache.shared().initialize()
        tearDown_request()
    }
}
