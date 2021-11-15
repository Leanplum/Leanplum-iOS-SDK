//
//  LeanplumPushNotificationsProxyiOS9Test.swift
//  LeanplumSDKTests
//
//  Created by Nikola Zagorchev on 4.11.21.
//  Copyright © 2021 Leanplum. All rights reserved.

import Foundation
import XCTest
@testable import Leanplum

class LeanplumPushNotificationsProxyiOS9Test: XCTestCase {
    
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
    
    func test_notification_applicationDidReceiveRemote_iOS9_background_receive() {
        NotificationTestHelper.setApplicationState(.background)
        
        let manager = Leanplum.notificationsManager() as! LeanplumNotificationsManagerMock
        manager.leanplum_application_ios9(UIApplication.shared, didReceiveRemoteNotification: userInfo) { result in }
        
        guard let notif = manager.userInfoProcessed, let occId = notif[NotificationTestHelper.occurrenceIdKey] else {
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
    
    func test_notification_applicationDidReceiveRemote_iOS9_active_receive() {
        let manager = Leanplum.notificationsManager() as! LeanplumNotificationsManagerMock
        manager.leanplum_application_ios9(UIApplication.shared, didReceiveRemoteNotification: userInfo) { result in }
        
        guard let notif = manager.userInfoProcessed, let occId = notif[NotificationTestHelper.occurrenceIdKey] else {
            XCTFail(NotificationTestHelper.occurrenceIdNilError)
            return
        }
        
        guard let isForeground = manager.foreground else {
            XCTFail(NotificationTestHelper.foregroundNilError)
            return
        }
        
        XCTAssertEqual(notificationId, String(describing: occId))
        XCTAssertTrue(isForeground)
    }
    
    /**
     * Tests notification is opened. Application became active from user tapping the notification, hence didReceiveRemoteNotification was executed.
     */
    func test_notification_applicationDidReceiveRemote_iOS9_active_open() {
        let manager = Leanplum.notificationsManager() as! LeanplumNotificationsManagerMock
        manager.proxy.resumedTimeInterval = Date().timeIntervalSince1970
        manager.leanplum_application_ios9(UIApplication.shared, didReceiveRemoteNotification: userInfo) { result in }
        
        guard let notif = manager.userInfoProcessed, let occId = notif[NotificationTestHelper.occurrenceIdKey] else {
            XCTFail(NotificationTestHelper.occurrenceIdNilError)
            return
        }
        
        guard manager.foreground == nil else {
            XCTFail(NotificationTestHelper.foregroundNotNilError)
            return
        }
        
        XCTAssertEqual(notificationId, String(describing: occId))
        XCTAssertEqual(LP_VALUE_DEFAULT_PUSH_ACTION, manager.actionName)
    }
    
    /**
     * Tests notification is opened. Application became active from user tapping the notification 300ms ago.
     * didReceiveRemoteNotification was executed by notification tap.
     */
    func test_notification_applicationDidReceiveRemote_iOS9_active_interval_open() {
        let manager = Leanplum.notificationsManager() as! LeanplumNotificationsManagerMock
        var date = Date()
        date.addTimeInterval(-0.3)
        manager.proxy.resumedTimeInterval = date.timeIntervalSince1970
        manager.leanplum_application_ios9(UIApplication.shared, didReceiveRemoteNotification: userInfo) { result in }
        
        guard let notif = manager.userInfoProcessed, let occId = notif[NotificationTestHelper.occurrenceIdKey] else {
            XCTFail(NotificationTestHelper.occurrenceIdNilError)
            return
        }
        
        guard manager.foreground == nil else {
            XCTFail(NotificationTestHelper.foregroundNotNilError)
            return
        }
        
        XCTAssertEqual(notificationId, String(describing: occId))
        XCTAssertEqual(LP_VALUE_DEFAULT_PUSH_ACTION, manager.actionName)
    }
    
    /**
     * Tests notification is receive in foreground. Application became active 1s ago. User did not tap on the notification.
     */
    func test_notification_applicationDidReceiveRemote_iOS9_active_interval_receive() {
        let manager = Leanplum.notificationsManager() as! LeanplumNotificationsManagerMock
        var date = Date()
        date.addTimeInterval(-1)
        manager.proxy.resumedTimeInterval = date.timeIntervalSince1970
        manager.leanplum_application_ios9(UIApplication.shared, didReceiveRemoteNotification: userInfo) { result in }
        
        guard let notif = manager.userInfoProcessed, let occId = notif[NotificationTestHelper.occurrenceIdKey] else {
            XCTFail(NotificationTestHelper.occurrenceIdNilError)
            return
        }
        
        guard let isForeground = manager.foreground else {
            XCTFail(NotificationTestHelper.foregroundNilError)
            return
        }
        
        XCTAssertEqual(notificationId, String(describing: occId))
        XCTAssertTrue(isForeground)
    }
    
    func test_notification_applicationDidReceiveRemote_iOS9_inactive_open() {
        NotificationTestHelper.setApplicationState(.inactive)
        
        let manager = Leanplum.notificationsManager() as! LeanplumNotificationsManagerMock
        manager.leanplum_application_ios9(UIApplication.shared, didReceiveRemoteNotification: userInfo) { result in }
        
        guard let notif = manager.userInfoProcessed, let occId = notif[NotificationTestHelper.occurrenceIdKey] else {
            XCTFail(NotificationTestHelper.occurrenceIdNilError)
            return
        }
        
        guard manager.foreground == nil else {
            XCTFail(NotificationTestHelper.foregroundNotNilError)
            return
        }
        
        XCTAssertEqual(notificationId, String(describing: occId))
        XCTAssertEqual(LP_VALUE_DEFAULT_PUSH_ACTION, manager.actionName)
    }
    
    /**
     * Tests notificationOpen is called when application is started from a local notificaton
     * applicationDidFinishLaunching is called first and then userNotificationCenter:didReceive may be called
     */
    @available(iOS 10, *)
    func test_local_notification_applicationDidFinishLaunching_inactive_open() {
        NotificationTestHelper.setApplicationState(.inactive)
    
        let localNotif = UILocalNotification()
        localNotif.userInfo = userInfo
        
        let options:[UIApplication.LaunchOptionsKey : Any] = [UIApplication.LaunchOptionsKey.localNotification:localNotif]
        let manager = Leanplum.notificationsManager() as! LeanplumNotificationsManagerMock
        manager.proxy.applicationDidFinishLaunching(launchOptions: options)
        
        guard let notif = manager.userInfoProcessed, let occId = notif[NotificationTestHelper.occurrenceIdKey] else {
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
    /**
     * Tests Local Notification Open for iOS 9. Notification is tapped which calls application:didReceive:
     */
    func test_local_notification_didReceive_open() {
        NotificationTestHelper.setApplicationState(.inactive)
        let localNotif = UILocalNotification()
        localNotif.userInfo = userInfo

        let manager = Leanplum.notificationsManager() as! LeanplumNotificationsManagerMock
        manager.proxy.application(didReceive: localNotif)
        
        guard let notif = manager.userInfoProcessed, let occId = notif[NotificationTestHelper.occurrenceIdKey] else {
            XCTFail(NotificationTestHelper.occurrenceIdNilError)
            return
        }

        guard manager.foreground == nil else {
            XCTFail(NotificationTestHelper.foregroundNotNilError)
            return
        }

        XCTAssertEqual(notificationId, String(describing: occId))
        XCTAssertEqual(LP_VALUE_DEFAULT_PUSH_ACTION, manager.actionName)
    }
}
