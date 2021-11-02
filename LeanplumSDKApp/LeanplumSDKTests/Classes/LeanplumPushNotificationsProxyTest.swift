//
//  LeanplumPushNotificationsProxyTest.swift
//  LeanplumSDKTests
//
//  Created by Nikola Zagorchev on 26.10.21.
//  Copyright © 2021 Leanplum. All rights reserved.

import Foundation
import XCTest
@testable import Leanplum

@available(iOS 13, *)
class LeanplumPushNotificationsProxyTest: XCTestCase {
    
    let origManagerSel = #selector(Leanplum.notificationsManager)
    let mockManagerSel = #selector(LeanplumPushNotificationsProxyTest.notificationsManagerMock)
    
    lazy var origManagerMethod = class_getClassMethod(Leanplum.self, origManagerSel)!
    lazy var mockManagerMethod = class_getClassMethod(LeanplumPushNotificationsProxyTest.self, mockManagerSel)!
    
    let appStateSel = #selector(getter: UIApplication.applicationState)
    let appStateMockSel = #selector(getter: LeanplumPushNotificationsProxyTest.applicationState)
    
    lazy var origAppStateMethod = class_getInstanceMethod(UIApplication.self, appStateSel)!
    lazy var mockAppStateMethod = class_getInstanceMethod(LeanplumPushNotificationsProxyTest.self, appStateMockSel)!
    
    static var mockApplicationState = UIApplication.State.active
    var applicationState:UIApplication.State {
        return LeanplumPushNotificationsProxyTest.mockApplicationState
    }
    
    final let occurrenceIdKey = "lp_occurrence_id"
    
    var userInfo:[AnyHashable : Any] = [
        "aps": [
            "alert": [
                "title": "Notification 1",
                "body": "Notification Body 1"
            ],
            "sound": "default",
            "content-available": 1,
            "badge": 1
        ],
        "_lpm": 1234567890,
        "_lpx": [
            "URL": "http://www.leanplum.com",
            "__name__": "Open URL"
        ],
        "lp_occurrence_id": "abc-123-def-456"
    ]
    
    @objc static func notificationsManagerMock() ->  LeanplumNotificationsManagerMock {
        return LeanplumNotificationsManagerMock.notificationsManager()
    }
    
    override func setUp() {
        method_exchangeImplementations(origManagerMethod, mockManagerMethod)
        method_exchangeImplementations(origAppStateMethod, mockAppStateMethod)
    }
    
    override func tearDown() {
        LeanplumNotificationsManagerMock.reset()
        method_exchangeImplementations(origManagerMethod, mockManagerMethod)
        method_exchangeImplementations(origAppStateMethod, mockAppStateMethod)
    }
    
    func updateNotifId() -> String {
        let newId = UUID().uuidString
        userInfo[occurrenceIdKey] = newId
        return newId
    }
    
    func test_userNotificationCenter_didReceive() {
        let id = updateNotifId()
        
        let manager = Leanplum.notificationsManager() as! LeanplumNotificationsManagerMock
        manager.proxy.userNotificationCenter(didReceive: UNNotificationResponse.testNotificationResponse(with: UNNotificationDefaultActionIdentifier, and: userInfo), withCompletionHandler: {})
        
        guard let notif = manager.userInfoProcessed, let occId = notif[occurrenceIdKey] else {
            XCTFail("Expected notification occurrence id is nil")
            return
        }
        
        guard let actionName = manager.actionName else {
            XCTFail("Expected actionName is nil")
            return
        }
        
        XCTAssertEqual(id, String(describing: occId))
        XCTAssertEqual(LP_VALUE_DEFAULT_PUSH_ACTION, actionName)
    }
    
    func test_userNotificationCenter_willPresent() {
        let id = updateNotifId()
        let req = UNNotificationResponse.notificationRequest(with: UNNotificationDefaultActionIdentifier, and: userInfo)
        let notif = UNNotification(coder: UNNotificationResponseTestCoder(with: req))!
        
        let manager = Leanplum.notificationsManager() as! LeanplumNotificationsManagerMock
        manager.proxy.userNotificationCenter(willPresent: notif) { options in }
        
        guard let notif = manager.userInfoProcessed, let occId = notif[occurrenceIdKey] else {
            XCTFail("Expected notification occurrence id is nil")
            return
        }
        
        XCTAssertEqual(id, String(describing: occId))
        XCTAssertTrue(manager.foreground != nil && manager.foreground!)
    }
    
    func test_notification_applicationDidFinishLaunching() {
        let id = updateNotifId()
        LeanplumPushNotificationsProxyTest.mockApplicationState = .background
        
        let options:[UIApplication.LaunchOptionsKey : Any] = [UIApplication.LaunchOptionsKey.remoteNotification:userInfo]
        
        let manager = Leanplum.notificationsManager() as! LeanplumNotificationsManagerMock
        manager.proxy.applicationDidFinishLaunching(launchOptions: options)
        
        guard let notif = manager.userInfoProcessed, let occId = notif[occurrenceIdKey] else {
            XCTFail("Expected notification occurrence id is nil")
            return
        }
        
        guard let isForeground = manager.foreground else {
            XCTFail("Expected isForeground is nil. Notification Received method was not called")
            return
        }
        
        XCTAssertEqual(id, String(describing: occId))
        XCTAssertFalse(isForeground)
    }
}

@available(iOS 13, *)
@objc class LeanplumNotificationsManagerMock: LeanplumNotificationsManager {

    static var notificationsManagerManagerInstance = LeanplumNotificationsManagerMock()
    
    class func notificationsManager() -> LeanplumNotificationsManagerMock {
        return notificationsManagerManagerInstance
    }
    
    public var userInfoProcessed:[AnyHashable : Any]?
    public var actionName:String?
    public var foreground:Bool?
    
    override func notificationOpened(userInfo: [AnyHashable : Any], action: String = LP_VALUE_DEFAULT_PUSH_ACTION) {
        userInfoProcessed = userInfo
        actionName = action
    }
    
    override func notificationReceived(userInfo: [AnyHashable : Any], isForeground: Bool) {
        userInfoProcessed = userInfo
        foreground = isForeground
    }
    
    class func reset() {
        notificationsManagerManagerInstance = LeanplumNotificationsManagerMock()
    }
}

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
