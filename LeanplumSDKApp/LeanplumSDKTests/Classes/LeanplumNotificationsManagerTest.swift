//
//  LeanplumNotificationsManagerTest.swift
//  LeanplumSDKTests
//
//  Created by Nikola Zagorchev on 9.11.21.
//  Copyright © 2021 Leanplum. All rights reserved.

import Foundation
import XCTest
@testable import Leanplum

@available(iOS 10, *)
class LeanplumNotificationsManagerTest: XCTestCase {
    
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
        ]
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
        "lp_occurrence_id": "5813dbe3-214d-4031-a3ad-a124b38e0b97",
    ]

    let userInfoActionOpenURLMuteInsideTrue:[AnyHashable : Any] = [
        "_lpu": 6527720202764288,
        "_lpx":     [
            "URL": "http://www.test.com",
            "__name__": "Open URL",
        ],
        "lp_occurrence_id" : "ba77fe0a-d020-4a34-a79b-d388232deee3",
    ]

    let userInfoNoActionMuteInsideFalse:[AnyHashable : Any] = [
        "_lpn": 6527720202764288,
        "_lpx":     [
            "__name__": "",
        ],
        "apns-push-type": "alert",
        "lp_occurrence_id": "c5231787-4514-491b-b943-b99e9d9f36a0",
    ]

    // MARK: Setup and Teardown
    override func setUp() {
        LPInternalState.shared().issuedStart = true
        VarCache.shared().applyVariableDiffs(nil, messages: nil, variants: nil, localCaps: nil, regions: nil, variantDebugInfo: nil, varsJson: nil, varsSignature: nil)
    }
    
    override class func tearDown() {
        LPInternalState.shared().issuedStart = false
        LeanplumNotificationsManagerTest.showExecuted = false
    }
    
    // MARK: LPUIAlert:show mock
    func show(withTitle title: String, message: String, cancelButtonTitle: String, otherButtonTitles: [Any]?, block: LeanplumUIAlertCompletionBlock? = nil) {
        // self is LPUIAlert
        LeanplumNotificationsManagerTest.showExecuted = true
        let info = LeanplumNotificationsManagerTest.userInfo as NSDictionary
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
            let lpx = LeanplumNotificationsManagerTest.userInfo["_lpx"] as! [AnyHashable:Any]
            XCTAssertEqual(String(describing: lpx[LPMT_ARG_URL]!), context.string(name: "URL")!)
            XCTAssertEqual(String(describing: LeanplumNotificationsManagerTest.userInfo["_lpm"]!), context.messageId)
            XCTAssertEqual(LP_PUSH_NOTIFICATION_ACTION, context.parent?.name)
            onRunActionNamedExpectation.fulfill()
            return false
        }
        
        Leanplum.notificationsManager().notificationOpened(userInfo: LeanplumNotificationsManagerTest.userInfo)
        wait(for: [onRunActionNamedExpectation], timeout: timeout)
    }
    
    func test_notification_open_run_custom_action() {
        let onRunActionNamedExpectation = expectation(description: "Notification Open Action - Custom Action")
        
        Leanplum.defineAction(name: LPMT_OPEN_URL_NAME, kind: .action, args: []) { context in
            let url = (LeanplumNotificationsManagerTest.userInfo as NSDictionary).value(forKeyPath: "_lpc.MyAction.URL")!
            XCTAssertEqual(String(describing: url), context.string(name: LPMT_ARG_URL)!)
            XCTAssertEqual(String(describing: LeanplumNotificationsManagerTest.userInfo["_lpm"]!), context.messageId)
            XCTAssertEqual(LP_PUSH_NOTIFICATION_ACTION, context.parent?.name)
            
            onRunActionNamedExpectation.fulfill()
            return false
        }
        
        Leanplum.notificationsManager().notificationOpened(userInfo: LeanplumNotificationsManagerTest.userInfo, action: "MyAction")
        wait(for: [onRunActionNamedExpectation], timeout: timeout)
    }
    
    /**
     * Tests LPUIAlert is shown with correct data when notification is received when the app is in foreground and the notification is not muted
     */
    func test_notification_foreground_alert_shown() {
        let lpAlertShowMethod = class_getClassMethod(LPUIAlert.self, #selector(LPUIAlert.show(withTitle:message:cancelButtonTitle:otherButtonTitles:block:)))!
        let testShowMethod = class_getInstanceMethod(LeanplumNotificationsManagerTest.self, #selector(LeanplumNotificationsManagerTest.show(withTitle:message:cancelButtonTitle:otherButtonTitles:block:)))!
        let lpAlertShowImp = method_setImplementation(lpAlertShowMethod, method_getImplementation(testShowMethod))
        defer {
            method_setImplementation(lpAlertShowMethod, lpAlertShowImp)
        }
        
        Leanplum.notificationsManager().notificationReceived(userInfo: LeanplumNotificationsManagerTest.userInfo, isForeground: true)
        XCTAssertTrue(LeanplumNotificationsManagerTest.showExecuted)
        method_setImplementation(lpAlertShowMethod, lpAlertShowImp)
    }
    
    /**
     * Tests LPUIAlert tap on View executes Notification Open action
     */
    func test_notification_foreground_alert_open() {
        let onRunActionNamedExpectation = expectation(description: "Notification Alert -> Alert View -> Open Action")
        
        Leanplum.defineAction(name: LPMT_OPEN_URL_NAME, kind: .action, args: []) { context in
            let lpx = LeanplumNotificationsManagerTest.userInfo["_lpx"] as! [AnyHashable:Any]
            XCTAssertEqual(String(describing: lpx[LPMT_ARG_URL]!), context.string(name: LPMT_ARG_URL)!)
            XCTAssertEqual(String(describing: LeanplumNotificationsManagerTest.userInfo["_lpm"]!), context.messageId)
            XCTAssertEqual(LP_PUSH_NOTIFICATION_ACTION, context.parent?.name)
            onRunActionNamedExpectation.fulfill()
            return false
        }
        
        // Other UIAlertControllers can block the notification LPUIAlert
        // Dismiss all controllers so after notificationReceived is executed, the top one will be the LPUIAlert
        dismissAllPresentedControllers(block: {
            Leanplum.notificationsManager().notificationReceived(userInfo: LeanplumNotificationsManagerTest.userInfo, isForeground: true)
            self.getTopController()?.tapButton(atIndex: 1)
        })
        
        wait(for: [onRunActionNamedExpectation], timeout: timeout)
    }
    
    /**
     * Tests mute inside app correctly mutes notifications
     */
    func test_mute_inside_app() {
        XCTAssertFalse(LeanplumUtils.isMuted(LeanplumNotificationsManagerTest.userInfo))
        XCTAssertTrue(LeanplumUtils.isMuted(userInfoNoActionMuteInsideTrue))
        XCTAssertTrue(LeanplumUtils.isMuted(userInfoNoActionMuteInsideFalse))
        XCTAssertTrue(LeanplumUtils.isMuted(userInfoActionOpenURLMuteInsideTrue))
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
