//
//  NotificationsManagerTest.swift
//  LeanplumSDKTests
//
//  Created by Nikola Zagorchev on 9.11.21.
//  Copyright © 2021 Leanplum. All rights reserved.

import Foundation
import XCTest
@testable import Leanplum

@available(iOS 10, *)
class NotificationsManagerTest: XCTestCase {
    
    let timeout:TimeInterval = 5
    static var showExecuted = false
    static let userInfo:[AnyHashable : Any] = [
        "aps": [
            "alert": [
                "title": "Notification 1",
                "body": "Notification Body 1"
            ]
        ],
        "_lpm": 1234567890,
        "_lpx": [
            "URL": "http://www.leanplum.com",
            "__name__": "Open URL"
        ],
        "_lpc": [
            "MyAction": [
                "URL": "http://www.my-action.com",
                "__name__": "Open URL"
            ]
        ],
        "lp_sent_time": 12345.0,
        "lp_occurrence_id": "5813dbe3-214d-4031-a3ad-a124b38e0b97"
    ]
    
    // MARK: Muted Notifications    
    let userInfoNoActionMuteInsideTrue:[AnyHashable : Any] = [
        "_lpv": 6527720202764288,
        "_lpx": [
            "__name__" : "",
        ],
        "apns-push-type": "alert",
        "aps": [
            "alert": [
                "body": "test",
                "subtitle": "sub",
                "title": "title",
            ],
            "content-available": 1,
        ],
        "lp_occurrence_id": "5813dbe3-214d-4031-a3ad-a124b38e0b97"
    ]

    let userInfoActionOpenURLMuteInsideTrue:[AnyHashable : Any] = [
        "_lpu": 6527720202764288,
        "_lpx": [
            "URL": "http://www.test.com",
            "__name__": "Open URL",
        ],
        "lp_occurrence_id" : "ba77fe0a-d020-4a34-a79b-d388232deee3"
    ]

    let userInfoNoActionMuteInsideFalse:[AnyHashable : Any] = [
        "_lpn": 6527720202764288,
        "_lpx": [
            "__name__": "",
        ],
        "apns-push-type": "alert",
        "lp_occurrence_id": "c5231787-4514-491b-b943-b99e9d9f36a0"
    ]
    
    // MARK: Setup and Teardown
    override func setUp() {
        LPInternalState.shared().issuedStart = true
        Leanplum.Constants.shared().isDevelopmentModeEnabled = false
        VarCache.shared().applyVariableDiffs(nil, messages: nil, variants: nil, localCaps: nil, regions: nil, variantDebugInfo: nil, varsJson: nil, varsSignature: nil)
    }
    
    override func tearDown() {
        LPInternalState.shared().issuedStart = false
        NotificationsManagerTest.showExecuted = false
        VarCache.shared().reset()
        VarCache.shared().initialize()
        LPEventDataManager.deleteEvents(withLimit: LPEventDataManager.count())
    }
    
    func setUp_request() {
        LPRequestFactory.swizzle_methods()
        LPRequestSender.swizzle_methods()
    }
    
    func tearDown_request() {
        LPRequestSender.reset()
        LPRequestFactory.unswizzle_methods()
        LPRequestSender.unswizzle_methods()
    }
    
    // MARK: LPUIAlert:show mock
    func show(withTitle title: String, message: String, cancelButtonTitle: String, otherButtonTitles: [Any]?, block: LeanplumUIAlertCompletionBlock? = nil) {
        // self is LPUIAlert
        NotificationsManagerTest.showExecuted = true
        let info = NotificationsManagerTest.userInfo as NSDictionary
        let appName = "LeanplumSDKApp"
        let body = info.value(forKeyPath: "aps.alert.body") as! String
        XCTAssertEqual(title, appName)
        XCTAssertEqual(message, body)
        XCTAssertEqual(cancelButtonTitle, "Cancel")
        XCTAssertEqual(otherButtonTitles as! [String], ["View"])
    }
    
    // MARK: Tests
    func test_notification_open_run_action() {
        let onRunActionNamedExpectation = expectation(description: "Notification Open Action")
        
        Leanplum.defineAction(name: LPMT_OPEN_URL_NAME, kind: .action, args: []) { context in
            let lpx = NotificationsManagerTest.userInfo["_lpx"] as! [AnyHashable:Any]
            XCTAssertEqual(String(describing: lpx[LPMT_ARG_URL]!), context.string(name: "URL")!)
            XCTAssertEqual(String(describing: NotificationsManagerTest.userInfo["_lpm"]!), context.messageId)
            XCTAssertEqual(LP_PUSH_NOTIFICATION_ACTION, context.parent?.name)
            onRunActionNamedExpectation.fulfill()
            return false
        }
        
        Leanplum.notificationsManager().notificationOpened(userInfo: NotificationsManagerTest.userInfo)
        wait(for: [onRunActionNamedExpectation], timeout: timeout)
    }
    
    func test_notification_open_run_custom_action() {
        let onRunActionNamedExpectation = expectation(description: "Notification Open Action - Custom Action")
        
        Leanplum.defineAction(name: LPMT_OPEN_URL_NAME, kind: .action, args: []) { context in
            let url = (NotificationsManagerTest.userInfo as NSDictionary).value(forKeyPath: "_lpc.MyAction.URL")!
            XCTAssertEqual(String(describing: url), context.string(name: LPMT_ARG_URL)!)
            XCTAssertEqual(String(describing: NotificationsManagerTest.userInfo["_lpm"]!), context.messageId)
            XCTAssertEqual(LP_PUSH_NOTIFICATION_ACTION, context.parent?.name)
            
            onRunActionNamedExpectation.fulfill()
            return false
        }
        
        Leanplum.notificationsManager().notificationOpened(userInfo: NotificationsManagerTest.userInfo, action: "MyAction")
        wait(for: [onRunActionNamedExpectation], timeout: timeout)
    }
    
    /**
     * Tests LPUIAlert is shown with correct data when notification is received when the app is in foreground and the notification is not muted
     */
    func test_notification_foreground_alert_shown() {
        let lpAlertShowMethod = class_getClassMethod(LPUIAlert.self, #selector(LPUIAlert.show(withTitle:message:cancelButtonTitle:otherButtonTitles:block:)))!
        let testShowMethod = class_getInstanceMethod(NotificationsManagerTest.self, #selector(NotificationsManagerTest.show(withTitle:message:cancelButtonTitle:otherButtonTitles:block:)))!
        let lpAlertShowImp = method_setImplementation(lpAlertShowMethod, method_getImplementation(testShowMethod))
        defer {
            method_setImplementation(lpAlertShowMethod, lpAlertShowImp)
        }
        
        Leanplum.notificationsManager().notificationReceived(userInfo: NotificationsManagerTest.userInfo, isForeground: true)
        XCTAssertTrue(NotificationsManagerTest.showExecuted)
        method_setImplementation(lpAlertShowMethod, lpAlertShowImp)
    }
    
    /**
     * Tests LPUIAlert tap on View executes Notification Open action
     */
    func test_notification_foreground_alert_open() {
        let onRunActionNamedExpectation = expectation(description: "Notification Alert -> Alert View -> Open Action")
        let dismissControllerExp = expectation(description: "Dismiss Controller")
        Leanplum.defineAction(name: LPMT_OPEN_URL_NAME, kind: .action, args: []) { context in
            let lpx = NotificationsManagerTest.userInfo["_lpx"] as! [AnyHashable:Any]
            XCTAssertEqual(String(describing: lpx[LPMT_ARG_URL]!), context.string(name: LPMT_ARG_URL)!)
            XCTAssertEqual(String(describing: NotificationsManagerTest.userInfo["_lpm"]!), context.messageId)
            XCTAssertEqual(LP_PUSH_NOTIFICATION_ACTION, context.parent?.name)
            onRunActionNamedExpectation.fulfill()
            return false
        }
        
        if UIApplication.shared.keyWindow == nil {
            let window = UIWindow()
            window.rootViewController = UIViewController()
            window.makeKeyAndVisible()
        }
        
        // Other UIAlertControllers can block the notification LPUIAlert
        // Dismiss all controllers so after notificationReceived is executed, the top one will be the LPUIAlert
        dismissAllPresentedControllers(block: {
            Leanplum.notificationsManager().notificationReceived(userInfo: NotificationsManagerTest.userInfo, isForeground: true)
            self.getTopController()?.tapButton(atIndex: 1)
            self.getTopController()?.dismiss(animated: false, completion: {
                dismissControllerExp.fulfill()
            })
        })
        
        wait(for: [onRunActionNamedExpectation, dismissControllerExp], timeout: timeout)
    }
    
    func test_notification_foreground_custom_block() {
        let onRunActionNamedExpectation = expectation(description: "LeanplumShouldHandleNotificationBlock")
        
        let shouldHandleBlock:LeanplumShouldHandleNotificationBlock = { (userInfo, handler) in
            XCTAssertEqual(String(describing: NotificationsManagerTest.userInfo[LP_KEY_PUSH_OCCURRENCE_ID]),
                           String(describing: userInfo[LP_KEY_PUSH_OCCURRENCE_ID]))
            onRunActionNamedExpectation.fulfill()
        }
        
        Leanplum.setShouldOpenNotificationHandler(shouldHandleBlock)
        Leanplum.notificationsManager().notificationReceived(userInfo: NotificationsManagerTest.userInfo, isForeground: true)
        
        wait(for: [onRunActionNamedExpectation], timeout: timeout)
        Leanplum.notificationsManager().shouldHandleNotificationBlock = nil
    }
    
    func test_notification_foreground_custom_block_open() {
        let onRunActionNamedExpectation = expectation(description: "LeanplumShouldHandleNotificationBlock -> Open Action")
        
        Leanplum.defineAction(name: LPMT_OPEN_URL_NAME, kind: .action, args: []) { context in
            let lpx = NotificationsManagerTest.userInfo["_lpx"] as! [AnyHashable:Any]
            XCTAssertEqual(String(describing: lpx[LPMT_ARG_URL]!), context.string(name: LPMT_ARG_URL)!)
            XCTAssertEqual(LP_PUSH_NOTIFICATION_ACTION, context.parent?.name)
            onRunActionNamedExpectation.fulfill()
            return false
        }
        
        let shouldHandleBlock:LeanplumShouldHandleNotificationBlock = { (userInfo, handler) in
            handler()
        }
        
        Leanplum.setShouldOpenNotificationHandler(shouldHandleBlock)
        Leanplum.notificationsManager().notificationReceived(userInfo: NotificationsManagerTest.userInfo, isForeground: true)
        
        wait(for: [onRunActionNamedExpectation], timeout: timeout)
        Leanplum.notificationsManager().shouldHandleNotificationBlock = nil
    }
    
    /**
     * Tests mute inside app correctly mutes notifications
     */
    func test_mute_inside_app() {
        XCTAssertFalse(Leanplum.notificationsManager().isMuted(NotificationsManagerTest.userInfo))
        XCTAssertTrue(Leanplum.notificationsManager().isMuted(userInfoNoActionMuteInsideTrue))
        XCTAssertTrue(Leanplum.notificationsManager().isMuted(userInfoNoActionMuteInsideFalse))
        XCTAssertTrue(Leanplum.notificationsManager().isMuted(userInfoActionOpenURLMuteInsideTrue))
    }
    
    // MARK: Tests Delivery Tracking
    func test_track_delivery() {
        class LeanplumNotificationsManagerDeliveryMock: NotificationsManager {
            public var deliveryInvocations = 0
            override func trackDelivery(userInfo: [AnyHashable : Any]) {
                self.deliveryInvocations += 1
            }
        }
        
        let userInfo:[AnyHashable : Any] = [
            "_lpm": 1234567890,
            "lp_occurrence_id": "5813dbe3-214d-4031-a3ad-a124b38e0a12",
            "_lpx":[]
        ]

        let mock = LeanplumNotificationsManagerDeliveryMock()
        mock.notificationOpened(userInfo: userInfo)
        XCTAssertEqual(mock.deliveryInvocations, 0)
        mock.notificationReceived(userInfo: userInfo, isForeground: false)
        XCTAssertEqual(mock.deliveryInvocations, 1)
        mock.notificationReceived(userInfo: userInfo, isForeground: true)
        XCTAssertEqual(mock.deliveryInvocations, 2)
    }
    
    /**
     * Tests Push Delivered event is tracked with the correct params
     */
    func test_track_delivery_req_params() {
        setUp_request()

        let onRequestExpectation = expectation(description: "Track Push Delivery Event Request")

        LPRequestSender.validate_request { method, apiMethod, params in
            XCTAssertEqual(apiMethod, "track")
            XCTAssertEqual(params?["event"] as? String, PUSH_DELIVERED_EVENT_NAME)

            let str = params?["params"] as? String
            guard let paramsStr = str else {
                XCTFail("Request has no parameters")
                return true
            }
            // The params come as a JSON string
            var eventParams = [String:String]()
            paramsStr
                .replacingOccurrences(of: "{", with: "")
                .replacingOccurrences(of: "}", with: "")
                .replacingOccurrences(of: "\"", with: "")
                .components(separatedBy: ",")
                .forEach { str in
                    let keyValue = str.components(separatedBy: ":")
                    eventParams[keyValue[0]] = keyValue[1]
                }
            
            XCTAssertEqual(eventParams[LP_KEY_PUSH_METRIC_CHANNEL], DEFAULT_PUSH_CHANNEL)
            XCTAssertEqual(eventParams[LP_KEY_PUSH_METRIC_MESSAGE_ID],
                           Utilities.messageIdFromUserInfo(NotificationsManagerTest.userInfo))
            XCTAssertEqual(eventParams[LP_KEY_PUSH_METRIC_OCCURRENCE_ID],
                           Leanplum.notificationsManager().getNotificationId(NotificationsManagerTest.userInfo))
            XCTAssertEqual(Double(eventParams[LP_KEY_PUSH_METRIC_SENT_TIME]!),
                           NotificationsManagerTest.userInfo[LP_KEY_PUSH_SENT_TIME] as? Double)

            onRequestExpectation.fulfill()
            return true
        }


        Leanplum.notificationsManager().trackDelivery(userInfo: NotificationsManagerTest.userInfo)
        wait(for: [onRequestExpectation], timeout: timeout)
        tearDown_request()
    }
    
    func test_not_track_delivery_local() {
        setUp_request()

        let onRequestExpectation = expectation(description: "Track Push Delivery Event Request")
        LPRequestSender.validate_request { method, apiMethod, params in
            XCTFail("Push Delivery must not be tracked for local notifications")
            onRequestExpectation.fulfill()
            return true
        }

        let localUserInfo:[AnyHashable : Any] = [
            "_lpm": 1234567890,
            "lp_occurrence_id": "5813dbe3-214d-4031-a3ad-a124b38e0b97",
            "_lpl":true,
            "_lpx":[]
        ]

        Leanplum.notificationsManager().trackDelivery(userInfo: localUserInfo)
        let result = XCTWaiter.wait(for: [onRequestExpectation], timeout: 2.0)
        XCTAssertEqual(result, XCTWaiter.Result.timedOut)
        tearDown_request()
    }
    
    func test_not_track_delivery_disabled() {
        setUp_request()

        let onRequestExpectation = expectation(description: "Track Push Delivery Event Request")
        LPRequestSender.validate_request { method, apiMethod, params in
            XCTFail("Push Delivery must not be tracked when tracking is disabled")
            onRequestExpectation.fulfill()
            return true
        }

        let userInfo:[AnyHashable : Any] = [
            "_lpm": 1234567890,
            "lp_occurrence_id": "5813dbe3-214d-4031-a3ad-a124b38e0a12",
            "_lpx":[]
        ]

        Leanplum.setPushDeliveryTrackingEnabled(false)
        Leanplum.notificationsManager().trackDelivery(userInfo: userInfo)
        let result = XCTWaiter.wait(for: [onRequestExpectation], timeout: 2.0)
        XCTAssertEqual(result, XCTWaiter.Result.timedOut)
        Leanplum.setPushDeliveryTrackingEnabled(true)
        tearDown_request()
    }
    
    // MARK: View Controller Helper Functions
    func getTopController() -> UIAlertController? {
        var ctrl = UIApplication.shared.keyWindow?.rootViewController?.presentedViewController
        while(ctrl?.presentedViewController != nil){
            ctrl = ctrl?.presentedViewController
        }
        return (ctrl as? UIAlertController)
    }
    
    /**
     * Dismisses all presentedViewControllers then executes the block
     */
    func dismissAllPresentedControllers(block: @escaping () -> Void) {
        if let ctrl = getTopController() {
            ctrl.dismiss(animated: false, completion: {
                self.dismissAllPresentedControllers(block: block)
            })
        } else {
            block()
        }
    }
}

extension UIAlertController {
    typealias AlertHandler = @convention(block) (UIAlertAction) -> Void
    
    func tapButton(atIndex index: Int) {
        guard let block = actions[index].value(forKey: "handler") else { return }
        let handler = unsafeBitCast(block as AnyObject, to: AlertHandler.self)
        handler(actions[index])
    }
}
