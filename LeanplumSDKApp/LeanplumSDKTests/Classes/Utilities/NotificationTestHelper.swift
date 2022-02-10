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
    
    private static let origManagerMethod = class_getClassMethod(Leanplum.self, #selector(Leanplum.notificationsManager))!
    private static let mockManagerMethod = class_getClassMethod(NotificationTestHelper.self, #selector(NotificationTestHelper.notificationsManagerMock))!
    
    private static let origAppStateMethod = class_getInstanceMethod(UIApplication.self, #selector(getter: UIApplication.applicationState))!
    private static let mockAppStateMethod = class_getInstanceMethod(NotificationTestHelper.self, #selector(getter: NotificationTestHelper.applicationState))!
    
    private static var appStateImp:IMP?
    
    static let occurrenceIdNilError = "Notification occurrence id must not be nil."
    static let foregroundNilError = "IsForeground must not be nil. Notification Received method was not called"
    static let foregroundNotNilError = "Notification Received method was called. Expected Notification Open to be called instead."
    static let actionNameNilError = "ActionName must not be nil. Verify if Notification Open method was called."
    
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
    @objc var applicationState: UIApplication.State {
        return NotificationTestHelper.mockApplicationState
    }
    
    @objc static func notificationsManagerMock() ->  NotificationsManager {
        return NotificationsManagerMock.notificationsManager()
    }
    
    func updateNotifId() -> String {
        let newId = UUID().uuidString
        userInfo[Constants.PushNotifications.Keys.occurrenceId] = newId
        return newId
    }
    
    class func setUp() {
        mockManager()
        mockAppState()
    }
    
    class func cleanUp() {
        NotificationsManagerMock.reset()
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
