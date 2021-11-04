//
//  NotificationTestUtils.swift
//  LeanplumSDKTests
//
//  Created by Nikola Zagorchev on 4.11.21.
//  Copyright © 2021 Leanplum. All rights reserved.

import Foundation
@testable import Leanplum

class NotificationTestUtils {
    
    let origManagerSel = #selector(Leanplum.notificationsManager)
    let mockManagerSel = #selector(NotificationTestUtils.notificationsManagerMock)
    
    lazy var origManagerMethod = class_getClassMethod(Leanplum.self, origManagerSel)!
    lazy var mockManagerMethod = class_getClassMethod(NotificationTestUtils.self, mockManagerSel)!
    
    let appStateSel = #selector(getter: UIApplication.applicationState)
    let appStateMockSel = #selector(getter: NotificationTestUtils.applicationState)
    
    lazy var origAppStateMethod = class_getInstanceMethod(UIApplication.self, appStateSel)!
    lazy var mockAppStateMethod = class_getInstanceMethod(NotificationTestUtils.self, appStateMockSel)!
    
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
    
    static var mockApplicationState = UIApplication.State.active
    @objc var applicationState:UIApplication.State {
        return NotificationTestUtils.mockApplicationState
    }
    
    @objc static func notificationsManagerMock() ->  LeanplumNotificationsManager {
        return LeanplumNotificationsManagerMock.notificationsManager()
    }
    
    func updateNotifId() -> String {
        let newId = UUID().uuidString
        userInfo[NotificationTestUtils.occurrenceIdKey] = newId
        return newId
    }
    
    func setUp() {
        method_exchangeImplementations(origManagerMethod, mockManagerMethod)
        method_exchangeImplementations(origAppStateMethod, mockAppStateMethod)
    }
    
    func tearDown() {
        LeanplumNotificationsManagerMock.reset()
        NotificationTestUtils.mockApplicationState = UIApplication.shared.applicationState
        method_exchangeImplementations(origManagerMethod, mockManagerMethod)
        method_exchangeImplementations(origAppStateMethod, mockAppStateMethod)
    }
}
