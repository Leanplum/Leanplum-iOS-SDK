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
    
    let orig = #selector(Leanplum.notificationsManager)
    let mock = #selector(LeanplumPushNotificationsProxyTest.notificationsManagerMock)
    
    lazy var newMethod = class_getClassMethod(LeanplumPushNotificationsProxyTest.self, mock)!
    lazy var origMethod = class_getClassMethod(Leanplum.self, orig)!
    
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
    
    override func setUp() {
        method_exchangeImplementations(origMethod, newMethod)
    }
    
    override func tearDown() {
        method_exchangeImplementations(origMethod, newMethod)
    }
    
    @objc static func notificationsManagerMock() ->  LeanplumNotificationsManagerMock {
        return LeanplumNotificationsManagerMock.notificationsManager()
    }
    
    func updateNotifId() -> String {
        let newId = UUID().uuidString
        userInfo["lp_occurrence_id"] = newId
        return newId
    }
    
    func test_userNotificationCenter_didReceive() {
        let id = updateNotifId()
        
        let manager = Leanplum.notificationsManager() as! LeanplumNotificationsManagerMock
        manager.proxy.userNotificationCenter(didReceive: UNNotificationResponse.testNotificationResponse(with: UNNotificationDefaultActionIdentifier, and: userInfo), withCompletionHandler: {})
        
        XCTAssertEqual(id, String(describing: manager.notif?["lp_occurrence_id"]))
        XCTAssertEqual(LP_VALUE_DEFAULT_PUSH_ACTION, manager.actionName)
    }
    
    func test_userNotificationCenter_willPresent() {
        let id = updateNotifId()
        let req = UNNotificationResponse.notificationRequest(with: UNNotificationDefaultActionIdentifier, and: userInfo)
        let notif = UNNotification(coder: UNNotificationResponseTestCoder(with: req))!
        
        let manager = Leanplum.notificationsManager() as! LeanplumNotificationsManagerMock
        manager.proxy.userNotificationCenter(willPresent: notif) { options in
        
        }
        
        XCTAssertEqual(id, String(describing: manager.notif?["lp_occurrence_id"]))
        XCTAssertTrue(manager.foreground != nil && manager.foreground!)
    }
}

class UIApplicationMock: UIApplication {
    override var applicationState: UIApplication.State {
        return UIApplication.State.active
    }
}

@available(iOS 13, *)
@objc class LeanplumNotificationsManagerMock: LeanplumNotificationsManager {
    
    static let notificationsManagerManagerInstance: LeanplumNotificationsManagerMock = {
        var managerInstance = LeanplumNotificationsManagerMock()
        return managerInstance
    }()
    
    override init() {
        super.init()
        //proxy = LeanplumPushNotificationsProxyMock()
        proxy.application = UIApplicationMock.shared
    }
    
    class func notificationsManager() -> LeanplumNotificationsManagerMock {
        // `dispatch_once()` call was converted to a static variable initializer
        return notificationsManagerManagerInstance
    }
    
    public var notif:[AnyHashable : Any]?
    public var actionName:String?
    public var foreground:Bool?
    
    override func notificationOpened(userInfo: [AnyHashable : Any], action: String = LP_VALUE_DEFAULT_PUSH_ACTION) {
        notif = userInfo
        actionName = action
    }
    
    override func notificationReceived(userInfo: [AnyHashable : Any], isForeground: Bool) {
        notif = userInfo
        foreground = isForeground
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
