//
//  ActionScheduler.swift
//  LeanplumSDK
//
//  Created by Milos Jakovljevic on 20.09.21.
//

import Foundation

protocol ActionSchedulerDelegate: AnyObject {
    
    func onActionDelayed(action: ActionManager.Action)
}

public class ActionScheduler {
    
    weak var delegate: ActionSchedulerDelegate?

    func schedule(action: ActionManager.Action, delay: Int) {
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(delay)) {
            self.delegate?.onActionDelayed(action: action)
        }
    }
}
