//
//  NotificationTestHelper.swift
//  LeanplumSDKTests
//
//  Created by Nikola Zagorchev on 4.11.21.
//  Copyright © 2021 Leanplum. All rights reserved.

import Foundation
import XCTest
@testable import Leanplum

class NotificationTestHelper {
    
    static let origManagerMethod = class_getClassMethod(Leanplum.self, #selector(Leanplum.notificationsManager))!
    static let mockManagerMethod = class_getClassMethod(NotificationTestHelper.self, #selector(NotificationTestHelper.notificationsManagerMock))!
    
    static let origAppStateMethod = class_getInstanceMethod(UIApplication.self, #selector(getter: UIApplication.applicationState))!
    static let mockAppStateMethod = class_getInstanceMethod(NotificationTestHelper.self, #selector(getter: NotificationTestHelper.applicationState))!
    
    private static var appStateImp:IMP?
    
    static let occurrenceIdKey = "lp_occurrence_id"
    
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
    
    private static var mockApplicationState = UIApplication.State.active
    @objc var applicationState:UIApplication.State {
        return NotificationTestHelper.mockApplicationState
    }
    
    @objc static func notificationsManagerMock() ->  LeanplumNotificationsManager {
        return LeanplumNotificationsManagerMock.notificationsManager()
    }
    
    func updateNotifId() -> String {
        let newId = UUID().uuidString
        userInfo[NotificationTestHelper.occurrenceIdKey] = newId
        return newId
    }
    
    class func setUp() {
        mockManager()
        mockAppState()
    }
    
    class func cleanUp() {
        LeanplumNotificationsManagerMock.reset()
        NotificationTestHelper.mockApplicationState = .active
    }
    
    class func tearDown() {
        restoreManager()
        restoreAppState()
    }
    
    class func setApplicationState(_ state: UIApplication.State) {
        mockApplicationState = state
    }

    class func mockManager() {
        method_exchangeImplementations(origManagerMethod, mockManagerMethod)
    }
    
    class func restoreManager() {
        method_exchangeImplementations(mockManagerMethod, origManagerMethod)
    }
    
    class func mockAppState() {
        let mockAppStateImp = method_getImplementation(mockAppStateMethod)
        appStateImp = method_setImplementation(origAppStateMethod, mockAppStateImp)
    }
    
    class func restoreAppState() {
        guard let imp = appStateImp else { return }
        method_setImplementation(origAppStateMethod, imp)
    }
}
