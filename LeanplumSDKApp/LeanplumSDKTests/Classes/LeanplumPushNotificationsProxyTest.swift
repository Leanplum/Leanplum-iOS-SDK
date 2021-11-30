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
    
    let utils = NotificationTestHelper()
    var notificationId = ""
    var userInfo:[AnyHashable : Any] {
        return utils.userInfo
    }
    
    override class func setUp() {
        NotificationTestHelper.setUp()
    }
    
    override class func tearDown() {
        NotificationTestHelper.tearDown()
    }

    override func setUp() {
        notificationId = utils.updateNotifId()
    }
    
    override func tearDown() {
        NotificationTestHelper.cleanUp()
    }
    
    // MARK: UNUserNotificationCenter Tests
    func test_userNotificationCenter_didReceive() {
        let manager = Leanplum.notificationsManager() as! LeanplumNotificationsManagerMock
        let actionIdentifier = UNNotificationDefaultActionIdentifier
        manager.proxy.userNotificationCenter(didReceive: UNNotificationResponse.testNotificationResponse(with: actionIdentifier, and: userInfo), withCompletionHandler: {})
        
        guard let notif = manager.userInfoProcessed, let occId = notif[LP_KEY_PUSH_OCCURRENCE_ID] else {
            XCTFail(NotificationTestHelper.occurrenceIdNilError)
            return
        }
        
        guard let actionName = manager.actionName else {
            XCTFail(NotificationTestHelper.actionNameNilError)
            return
        }
        
        XCTAssertEqual(notificationId, String(describing: occId))
        // UNNotificationDefaultActionIdentifier action executes the LP_VALUE_DEFAULT_PUSH_ACTION
        XCTAssertEqual(LP_VALUE_DEFAULT_PUSH_ACTION, actionName)
    }
    
    func test_userNotificationCenter_didReceive_custom_action() {
        let manager = Leanplum.notificationsManager() as! LeanplumNotificationsManagerMock
        let actionIdentifier = "MyAction"
        manager.proxy.userNotificationCenter(didReceive: UNNotificationResponse.testNotificationResponse(with: actionIdentifier, and: userInfo), withCompletionHandler: {})
        
        guard let notif = manager.userInfoProcessed, let occId = notif[LP_KEY_PUSH_OCCURRENCE_ID] else {
            XCTFail(NotificationTestHelper.occurrenceIdNilError)
            return
        }
        
        guard let actionName = manager.actionName else {
            XCTFail(NotificationTestHelper.actionNameNilError)
            return
        }
        
        XCTAssertEqual(notificationId, String(describing: occId))
        XCTAssertEqual(actionIdentifier, actionName)
    }
    
    func test_userNotificationCenter_willPresent() {
        let req = UNNotificationResponse.notificationRequest(with: UNNotificationDefaultActionIdentifier, and: utils.userInfo)
        let notif = UNNotification(coder: UNNotificationResponseTestCoder(with: req))!
        
        let manager = Leanplum.notificationsManager() as! LeanplumNotificationsManagerMock
        manager.proxy.userNotificationCenter(willPresent: notif) { options in }
        
        guard let notifProcessed = manager.userInfoProcessed, let occId = notifProcessed[LP_KEY_PUSH_OCCURRENCE_ID] else {
            XCTFail(NotificationTestHelper.occurrenceIdNilError)
            return
        }
        
        XCTAssertEqual(notificationId, String(describing: occId))
        XCTAssertTrue(manager.foreground != nil && manager.foreground!)
    }
    
    func test_userNotificationCenter_willPresent_once() {
        let req = UNNotificationResponse.notificationRequest(with: UNNotificationDefaultActionIdentifier, and: utils.userInfo)
        let notif = UNNotification(coder: UNNotificationResponseTestCoder(with: req))!
        
        let manager = Leanplum.notificationsManager() as! LeanplumNotificationsManagerMock
        manager.proxy.userNotificationCenter(willPresent: notif) { options in }
        // didReceiveRemoteNotification is called after willPresent if push has content-available flag
        manager.proxy.didReceiveRemoteNotification(userInfo: userInfo) { result in }
        
        guard let notifProcessed = manager.userInfoProcessed, let occId = notifProcessed[LP_KEY_PUSH_OCCURRENCE_ID] else {
            XCTFail(NotificationTestHelper.occurrenceIdNilError)
            return
        }
        
        XCTAssertEqual(notificationId, String(describing: occId))
        XCTAssertTrue(manager.foreground != nil && manager.foreground!)
        // Ensure it is called only once by willPresent and not again by didReceiveRemoteNotification
        XCTAssertEqual(1, manager.methodInvocations)
    }
    
    // MARK: applicationDidFinishLaunching Tests
    /**
     * Tests notificationReceive(background) is called when application is woken up by remote notification.
     * applicationDidFinishLaunching is called first and then didReceiveRemoteNotification
     */
    func test_notification_applicationDidFinishLaunching_background() {
        NotificationTestHelper.setApplicationState(.background)
        let options:[UIApplication.LaunchOptionsKey : Any] = [UIApplication.LaunchOptionsKey.remoteNotification:userInfo]
        
        let manager = Leanplum.notificationsManager() as! LeanplumNotificationsManagerMock
        manager.proxy.applicationDidFinishLaunching(launchOptions: options)
        
        guard let notif = manager.userInfoProcessed, let occId = notif[LP_KEY_PUSH_OCCURRENCE_ID] else {
            XCTFail(NotificationTestHelper.occurrenceIdNilError)
            return
        }
        
        guard let isForeground = manager.foreground else {
            XCTFail(NotificationTestHelper.foregroundNilError)
            return
        }
        
        // Ensure correct notification
        XCTAssertEqual(notificationId, String(describing: occId))
        // Ensure notification received is called with background flag
        XCTAssertFalse(isForeground)
        
        XCTAssertFalse(Leanplum.notificationsManager().proxy.notificationOpenedFromStart)
        
        // Ensure notification is handled only once
        manager.proxy.didReceiveRemoteNotification(userInfo: userInfo) { result in }
        
        XCTAssertEqual(1, manager.methodInvocations)
        XCTAssertTrue(Leanplum.notificationsManager().proxy.isEqualToHandledNotification(userInfo: userInfo))
    }
    
    /**
     * Tests notificationOpen is called when application is started from a notificaton
     * applicationDidFinishLaunching is called first and then userNotificationCenter:didReceive may be called
     */
    func test_notification_applicationDidFinishLaunching_inactive_open() {
        NotificationTestHelper.setApplicationState(.inactive)
        let options:[UIApplication.LaunchOptionsKey : Any] = [UIApplication.LaunchOptionsKey.remoteNotification:userInfo]
        let manager = Leanplum.notificationsManager() as! LeanplumNotificationsManagerMock
        manager.proxy.applicationDidFinishLaunching(launchOptions: options)
        
        guard let notif = manager.userInfoProcessed, let occId = notif[LP_KEY_PUSH_OCCURRENCE_ID] else {
            XCTFail(NotificationTestHelper.occurrenceIdNilError)
            return
        }

        guard manager.foreground == nil else {
            XCTFail(NotificationTestHelper.foregroundNotNilError)
            return
        }

        XCTAssertEqual(notificationId, String(describing: occId))
        XCTAssertEqual(LP_VALUE_DEFAULT_PUSH_ACTION, manager.actionName)
        
        // Ensure notification is opened only once
        manager.proxy.userNotificationCenter(didReceive: UNNotificationResponse.testNotificationResponse(with: UNNotificationDefaultActionIdentifier, and: userInfo)) {
        }
        XCTAssertEqual(1, manager.methodInvocations)
        XCTAssertTrue(Leanplum.notificationsManager().proxy.notificationOpenedFromStart)
        XCTAssertTrue(Leanplum.notificationsManager().proxy.isEqualToHandledNotification(userInfo: userInfo))
    }
    
    // MARK: application:didReceiveRemoteNotification Tests
    
    func test_notification_applicationDidReceiveRemote_background() {
        NotificationTestHelper.setApplicationState(.background)
        let manager = Leanplum.notificationsManager() as! LeanplumNotificationsManagerMock
        manager.proxy.didReceiveRemoteNotification(userInfo: userInfo) { res in }
        
        guard let notif = manager.userInfoProcessed, let occId = notif[LP_KEY_PUSH_OCCURRENCE_ID] else {
            XCTFail(NotificationTestHelper.occurrenceIdNilError)
            return
        }
        
        guard let isForeground = manager.foreground else {
            XCTFail(NotificationTestHelper.foregroundNilError)
            return
        }
        
        XCTAssertEqual(notificationId, String(describing: occId))
        XCTAssertFalse(isForeground)
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
    
    override func decodeInt64(forKey key: String) -> Int64 {
        return 0
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
