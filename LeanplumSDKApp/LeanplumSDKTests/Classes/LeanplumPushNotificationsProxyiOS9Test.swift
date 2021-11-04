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
    
    func test_notification_applicationDidReceiveRemote_iOS9_background_receive() {
        NotificationTestUtils.mockApplicationState = .background
        
        let manager = Leanplum.notificationsManager() as! LeanplumNotificationsManagerMock
        manager.leanplum_application_ios9(UIApplication.shared, didReceiveRemoteNotification: userInfo) { result in
            
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
    }
    
    func test_notification_applicationDidReceiveRemote_iOS9_active_receive() {
        NotificationTestUtils.mockApplicationState = .active
        
        let manager = Leanplum.notificationsManager() as! LeanplumNotificationsManagerMock
        manager.leanplum_application_ios9(UIApplication.shared, didReceiveRemoteNotification: userInfo) { result in
            
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
        XCTAssertTrue(isForeground)
    }
    
    func test_notification_applicationDidReceiveRemote_iOS9_active_open() {
        NotificationTestUtils.mockApplicationState = .active
        
        let manager = Leanplum.notificationsManager() as! LeanplumNotificationsManagerMock
        manager.proxy.resumedTimeInterval = Date().timeIntervalSince1970
        manager.leanplum_application_ios9(UIApplication.shared, didReceiveRemoteNotification: userInfo) { result in
            
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
    }
    
    func test_notification_applicationDidReceiveRemote_iOS9_active_interval_open() {
        NotificationTestUtils.mockApplicationState = .active
        
        let manager = Leanplum.notificationsManager() as! LeanplumNotificationsManagerMock
        var date = Date()
        date.addTimeInterval(-0.3)
        manager.proxy.resumedTimeInterval = date.timeIntervalSince1970
        manager.leanplum_application_ios9(UIApplication.shared, didReceiveRemoteNotification: userInfo) { result in
            
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
    }
    
    func test_notification_applicationDidReceiveRemote_iOS9_active_interval_receive() {
        NotificationTestUtils.mockApplicationState = .active
        
        let manager = Leanplum.notificationsManager() as! LeanplumNotificationsManagerMock
        var date = Date()
        date.addTimeInterval(-1)
        manager.proxy.resumedTimeInterval = date.timeIntervalSince1970
        manager.leanplum_application_ios9(UIApplication.shared, didReceiveRemoteNotification: userInfo) { result in
            
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
        XCTAssertTrue(isForeground)
    }
    
    func test_notification_applicationDidReceiveRemote_iOS9_inactive_open() {
        NotificationTestUtils.mockApplicationState = .inactive
        
        let manager = Leanplum.notificationsManager() as! LeanplumNotificationsManagerMock
        manager.leanplum_application_ios9(UIApplication.shared, didReceiveRemoteNotification: userInfo) { result in
            
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
    }
}
