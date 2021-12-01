//
//  LeanplumPushNotificationSettingsTest.swift
//  LeanplumSDKTests
//
//  Created by Dejan Krstevski on 29.11.21.
//

import Foundation
import XCTest
@testable import Leanplum

@available(iOS 10.0, *)
class LeanplumPushNotificationSettingsTest: XCTestCase {
    
    var notificaitonSettings: LeanplumNotificationSettings!
    
    override func setUp() {
        super.setUp()
        notificaitonSettings = LeanplumNotificationSettings()
    }
    
    override class func setUp() {
        super.setUp()
        UNNotificationSettings.swizzleAuthorizationStatus()
        UNUserNotificationCenter.swizzleGetNotificationSettings()
        LPAPIConfig.shared().setAppId("testAppId", withAccessKey: "testAccessKey")
        LPAPIConfig.shared().deviceId = "testDeviceId"
        LPAPIConfig.shared().userId = "testUserId"
    }
    
//    func setUp_request() {
//        LPRequestFactory.swizzle_methods()
//        LPRequestSender.swizzle_methods()
//    }
//        
//    func tearDown_request() {
//        LPRequestSender.reset()
//        LPRequestFactory.unswizzle_methods()
//        LPRequestSender.unswizzle_methods()
//    }
    
    func testSetup() {
        notificaitonSettings.setUp()
        XCTAssertTrue(notificaitonSettings.updateSettings != nil)
    }
    
    func testGetSettingsWhenAuthorizationStatusNotDetermined() {
        let expectation = expectation(description: "Test authorizationStatus notDetermined")
        UNNotificationSettings.fakeAuthorizationStatus = .notDetermined
        notificaitonSettings.getSettings() { settings, areChanged in
            if let _ = settings[LP_PARAM_DEVICE_USER_NOTIFICATION_TYPES] as? UInt {
                fatalError()
            } else {
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 5)
    }
    
    func testGetSettingsWhenAuthorizationStatusDenied() {
        let expectation = expectation(description: "Test authorizationStatus denied")
        UNNotificationSettings.fakeAuthorizationStatus = .denied
        notificaitonSettings.getSettings() { settings, areChanged in
            if let types = settings[LP_PARAM_DEVICE_USER_NOTIFICATION_TYPES] as? UInt {
                if types == 0 {
                    expectation.fulfill()
                }
            }
        }
        wait(for: [expectation], timeout: 5)
    }
    
    func testGetSettingsWhenAuthorizationStatusAuthorized() {
        let expectation = expectation(description: "Test authorized")
        UNNotificationSettings.fakeAuthorizationStatus = .authorized
        notificaitonSettings.getSettings() { settings, areChanged in
            if let types = settings[LP_PARAM_DEVICE_USER_NOTIFICATION_TYPES] as? UInt {
                if types == 63 {
                    expectation.fulfill()
                }
            }
        }
        wait(for: [expectation], timeout: 5)
    }
    
    @available(iOS 12.0, *)
    func testGetSettingsWithProvisionalAuthorizationStatus() {
        let expectation = expectation(description: "Test provisional authorizationStatus")
        UNNotificationSettings.fakeAuthorizationStatus = .provisional
        notificaitonSettings.getSettings() { settings, areChanged in
            if let types = settings[LP_PARAM_DEVICE_USER_NOTIFICATION_TYPES] as? UInt {
                if types == 64 {
                    expectation.fulfill()
                }
            }
        }
        wait(for: [expectation], timeout: 5)
    }
    
    func testSaveAndRemoveSettings() {
        let testSettings: [AnyHashable: Any] = [LP_PARAM_DEVICE_USER_NOTIFICATION_TYPES: 7,
                            LP_PARAM_DEVICE_USER_NOTIFICATION_CATEGORIES: []]
        notificaitonSettings.save(testSettings)
        
        guard let savedSettings = UserDefaults.standard.value(forKey: notificaitonSettings.leanplumUserNotificationSettingsKey()) as? [AnyHashable : Any] else {
            fatalError()
        }
        XCTAssertTrue(NSDictionary(dictionary: savedSettings).isEqual(to: testSettings))
        
        notificaitonSettings.removeSettings()
        
        XCTAssertNil(UserDefaults.standard.value(forKey: notificaitonSettings.leanplumUserNotificationSettingsKey()))
    }
    
    override func tearDown() {
        UNNotificationSettings.fakeAuthorizationStatus = .notDetermined
    }
    
    override class func tearDown() {
        UNUserNotificationCenter.unswizzleGetNotificationSettings()
        UNNotificationSettings.unswizzleAuthorizationStatus()
        LPAPIConfig.shared().setAppId(nil, withAccessKey: nil)
        LPAPIConfig.shared().deviceId = nil
        LPAPIConfig.shared().userId = nil
    }
}

protocol LeanplumNotificaitonSettingsProtocol {
    func leanplumUserNotificationSettingsKey() -> String
}

extension LeanplumNotificationSettings: LeanplumNotificaitonSettingsProtocol {
    func leanplumUserNotificationSettingsKey() -> String {
        guard let appId = LPAPIConfig.shared().appId, let userId = LPAPIConfig.shared().userId, let deviceId = LPAPIConfig.shared().deviceId else {
            fatalError()
        }
        return String(format: LEANPLUM_DEFAULTS_USER_NOTIFICATION_SETTINGS_KEY, appId, userId, deviceId)
    }
}

@available(iOS 10.0, *)
extension UNUserNotificationCenter {
    static var originalMethod: OpaquePointer?
    static var swizzledMethod: OpaquePointer?
    
    static func swizzleGetNotificationSettings() {
        
        if let originalMethod = class_getInstanceMethod(self, #selector(getNotificationSettings(completionHandler:))),
           let swizzledMethod = class_getInstanceMethod(self, #selector(swizzledGetNotificationSettings(completionHandler:))) {
            self.originalMethod = originalMethod
            self.swizzledMethod = swizzledMethod
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }
    }
    
    static func unswizzleGetNotificationSettings() {
        if let originalMethod = self.originalMethod, let swizzledMethod = self.swizzledMethod {
            method_exchangeImplementations(swizzledMethod, originalMethod)
        }
    }
    
    @objc func swizzledGetNotificationSettings(completionHandler: @escaping (UNNotificationSettings) -> Void) {
        let settings = UNNotificationSettings.init(coder: MockNSCoder())!
        completionHandler(settings)
    }
}

@available(iOS 10.0, *)
extension UNNotificationSettings {
    static var fakeAuthorizationStatus: UNAuthorizationStatus = .authorized
    
    static var originalMethod: OpaquePointer?
    static var swizzledMethod: OpaquePointer?
    
    static func swizzleAuthorizationStatus() {
        if let originalMethod = class_getInstanceMethod(self, #selector(getter: authorizationStatus)),
           let swizzledMethod = class_getInstanceMethod(self, #selector(getter: swizzledAuthorizationStatus)) {
            self.originalMethod = originalMethod
            self.swizzledMethod = swizzledMethod
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }
    }
    
    static func unswizzleAuthorizationStatus() {
        if let originalMethod = self.originalMethod, let swizzledMethod = self.swizzledMethod {
            method_exchangeImplementations(swizzledMethod, originalMethod)
        }
    }
    
    @objc var swizzledAuthorizationStatus: UNAuthorizationStatus {
        return Self.fakeAuthorizationStatus
    }
}

@available(iOS 10.0, *)
class MockNSCoder: NSCoder {
    var authorizationStatus = UNAuthorizationStatus.authorized.rawValue
    
    override func decodeInt64(forKey key: String) -> Int64 {
        return Int64(authorizationStatus)
    }
    
    override func decodeBool(forKey key: String) -> Bool {
        return true
    }
}
