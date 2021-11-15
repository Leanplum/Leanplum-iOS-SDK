//
//  LeanplumNotificationsManagerMock.swift
//  LeanplumSDKTests
//
//  Created by Nikola Zagorchev on 4.11.21.
//  Copyright © 2021 Leanplum. All rights reserved.

import Foundation
@testable import Leanplum

class LeanplumNotificationsManagerMock: LeanplumNotificationsManager {
    
    static var notificationsManagerManagerInstance = LeanplumNotificationsManagerMock()
    
    class func notificationsManager() -> LeanplumNotificationsManagerMock {
        return notificationsManagerManagerInstance
    }
    
    public var userInfoProcessed:[AnyHashable : Any]?
    public var actionName:String?
    public var foreground:Bool?
    public var methodInvocations = 0
    
    override func notificationOpened(userInfo: [AnyHashable : Any], action: String = LP_VALUE_DEFAULT_PUSH_ACTION) {
        userInfoProcessed = userInfo
        actionName = action
        methodInvocations += 1
    }
    
    override func notificationReceived(userInfo: [AnyHashable : Any], isForeground: Bool) {
        userInfoProcessed = userInfo
        foreground = isForeground
        methodInvocations += 1
    }
    
    class func reset() {
        notificationsManagerManagerInstance = LeanplumNotificationsManagerMock()
    }
}
