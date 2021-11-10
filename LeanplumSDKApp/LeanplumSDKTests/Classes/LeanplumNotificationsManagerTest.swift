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
    
    static var showExecuted = false
    
    override func setUp() {
        LPInternalState.shared().issuedStart = true
        VarCache.shared().applyVariableDiffs(nil, messages: nil, variants: nil, localCaps: nil, regions: nil, variantDebugInfo: nil, varsJson: nil, varsSignature: nil)
    }
    
    override class func tearDown() {
        LPInternalState.shared().issuedStart = false
        LeanplumNotificationsManagerTest.showExecuted = false
    }
    
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
        
        dismissAllPresentedControllers(block: {
            Leanplum.notificationsManager().notificationReceived(userInfo: LeanplumNotificationsManagerTest.userInfo, isForeground: true)
            self.getTopController()?.tapButton(atIndex: 1)
        })
        
        wait(for: [onRunActionNamedExpectation], timeout: timeout)
    }
    
    func getTopController() -> UIAlertController? {
        var ctrl = UIApplication.shared.keyWindow?.rootViewController?.presentedViewController
        while(ctrl?.presentedViewController != nil){
            ctrl = ctrl?.presentedViewController
        }
        return (ctrl as? UIAlertController)
    }
    
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
