//
//  WeakTimer.swift
//  LeanplumSDK
//
//  Created by Nikola Zagorchev on 23.02.22.
//  Copyright © 2022 Leanplum. All rights reserved.

import Foundation

@objc(LPWeakTimer)
public class WeakTimer: NSObject {
    private weak var target: AnyObject?
    private let action: (Timer) -> Void
    
    private init(target: AnyObject,
                 action: @escaping (Timer) -> Void) {
        self.target = target
        self.action = action
    }
    
    @objc fileprivate func fire(timer: Timer) {
        if target != nil {
            action(timer)
        } else {
            timer.invalidate()
        }
    }
    
    @objc(scheduledTimerWithTimeInterval:target:userInfo:repeats:block:)
    public static func scheduledTimer(timeInterval: TimeInterval,
                                           target: AnyObject,
                                           userInfo:Any?,
                                           repeats: Bool,
                                           action: @escaping (Timer) -> Void) -> Timer {
        
        let target = WeakTimer(target: target, action: action)
        return .scheduledTimer(timeInterval: timeInterval,
                                    target: target,
                                    selector: #selector(fire),
                                    userInfo: userInfo,
                                    repeats: repeats)
    }
}
