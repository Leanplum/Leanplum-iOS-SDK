//
//  LeanplumPushNotificationsProxyTest.swift
//  LeanplumSDKTests
//
//  Created by Nikola Zagorchev on 26.10.21.
//  Copyright © 2021 Leanplum. All rights reserved.

import Foundation
import XCTest
@testable import Leanplum

@available(iOS 10, *)
class LeanplumPushNotificationsProxyTest: XCTestCase {
    
    let utils = NotificationTestUtils()
    var notificationId = ""
    var userInfo:[AnyHashable : Any] {
        return utils.userInfo
    }
    
    override func setUp() {
        notificationId = utils.updateNotifId()
        utils.setUp()
    }
    
    override func tearDown() {
        utils.tearDown()
    }
    
    // MARK: UNUserNotificationCenter Tests
    func test_userNotificationCenter_didReceive() {
        let manager = Leanplum.notificationsManager() as! LeanplumNotificationsManagerMock
        manager.proxy.userNotificationCenter(didReceive: UNNotificationResponse.testNotificationResponse(with: UNNotificationDefaultActionIdentifier, and: userInfo), withCompletionHandler: {})
        
        guard let notif = manager.userInfoProcessed, let occId = notif[NotificationTestUtils.occurrenceIdKey] else {
            XCTFail("Expected notification occurrence id is nil")
            return
        }
        
        guard let actionName = manager.actionName else {
            XCTFail("Expected actionName is nil")
            return
        }
        
        XCTAssertEqual(notificationId, String(describing: occId))
        XCTAssertEqual(LP_VALUE_DEFAULT_PUSH_ACTION, actionName)
    }
    
    func test_userNotificationCenter_willPresent() {
        let req = UNNotificationResponse.notificationRequest(with: UNNotificationDefaultActionIdentifier, and: utils.userInfo)
        let notif = UNNotification(coder: UNNotificationResponseTestCoder(with: req))!
        
        let manager = Leanplum.notificationsManager() as! LeanplumNotificationsManagerMock
        manager.proxy.userNotificationCenter(willPresent: notif) { options in }
        
        guard let notif = manager.userInfoProcessed, let occId = notif[NotificationTestUtils.occurrenceIdKey] else {
            XCTFail("Expected notification occurrence id is nil")
            return
        }
        
        XCTAssertEqual(notificationId, String(describing: occId))
        XCTAssertTrue(manager.foreground != nil && manager.foreground!)
    }
    
    // MARK: applicationDidFinishLaunching Tests
    func test_notification_applicationDidFinishLaunching_background() {
        NotificationTestUtils.mockApplicationState = .background
        
        let options:[UIApplication.LaunchOptionsKey : Any] = [UIApplication.LaunchOptionsKey.remoteNotification:userInfo]
        
        let manager = Leanplum.notificationsManager() as! LeanplumNotificationsManagerMock
        manager.proxy.applicationDidFinishLaunching(launchOptions: options)
        manager.proxy.didReceiveRemoteNotification(userInfo: userInfo) { result in
        }
        
        guard let notif = manager.userInfoProcessed, let occId = notif[NotificationTestUtils.occurrenceIdKey] else {
            XCTFail("Expected notification occurrence id is nil")
            return
        }
        
        guard let isForeground = manager.foreground else {
            XCTFail("Expected isForeground is nil. Notification Received method was not called")
            return
        }
        
        XCTAssertEqual(notificationId, String(describing: occId))
        XCTAssertFalse(isForeground)
        XCTAssertEqual(1, manager.methodInvocations)
    }
    
    func test_notification_applicationDidFinishLaunching_inactive_open() {
        NotificationTestUtils.mockApplicationState = .inactive
        
        let options:[UIApplication.LaunchOptionsKey : Any] = [UIApplication.LaunchOptionsKey.remoteNotification:userInfo]
        
        let manager = Leanplum.notificationsManager() as! LeanplumNotificationsManagerMock
        manager.proxy.applicationDidFinishLaunching(launchOptions: options)
        manager.proxy.userNotificationCenter(didReceive: UNNotificationResponse.testNotificationResponse(with: UNNotificationDefaultActionIdentifier, and: userInfo)) {
        }
        
        guard let notif = manager.userInfoProcessed, let occId = notif[NotificationTestUtils.occurrenceIdKey] else {
            XCTFail("Expected notification occurrence id is nil")
            return
        }
        
        guard manager.foreground == nil else {
            XCTFail("Notification Received method was called. Expected Notification Open to be called.")
            return
        }
        
        XCTAssertEqual(notificationId, String(describing: occId))
        XCTAssertEqual(LP_VALUE_DEFAULT_PUSH_ACTION, manager.actionName)
        XCTAssertEqual(1, manager.methodInvocations)
    }
}

// MARK: UNNotification Mocks
@available(iOS 10, *)
extension UNNotificationResponse {
    
    static func notificationRequest(with identifier:String, and parameters: [AnyHashable: Any]) -> UNNotificationRequest {
        let notificationContent = UNMutableNotificationContent()
        notificationContent.userInfo = parameters
        
        let dateInfo = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: Date())
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateInfo, repeats: false)
        
        let notificationRequest = UNNotificationRequest(identifier: identifier, content: notificationContent, trigger: trigger)
        
        return notificationRequest
    }
    
    static func testNotificationResponse(with identifier: String, and parameters: [AnyHashable: Any]) -> UNNotificationResponse {
        let request = notificationRequest(with: identifier, and: parameters)
        return UNNotificationResponse(coder: UNNotificationResponseTestCoder(with: request))!
    }
}

@available(iOS 10, *)
fileprivate class UNNotificationResponseTestCoder: NSCoder {
    
    private enum FieldKey: String {
        case date, request, sourceIdentifier, intentIdentifiers, notification, actionIdentifier, originIdentifier, targetConnectionEndpoint, targetSceneIdentifier
    }
    
    private let request: UNNotificationRequest
    override var allowsKeyedCoding: Bool { true }
    
    init(with request: UNNotificationRequest) {
        self.request = request
    }
    
    override func decodeObject(forKey key: String) -> Any? {
        let fieldKey = FieldKey(rawValue: key)
        switch fieldKey {
        case .date:
            return Date()
        case .request:
            return request
        case .sourceIdentifier, .actionIdentifier, .originIdentifier:
            return request.identifier
        case .notification:
            return UNNotification(coder: self)
        default:
            return nil
        }
    }
}
