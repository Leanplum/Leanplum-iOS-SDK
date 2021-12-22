//
//  ActionScheduler.swift
//  LeanplumSDK
//
//  Created by Milos Jakovljevic on 20.09.21.
//

import Foundation

protocol ActionSchedulerDelegate: AnyObject {
    func onActionDelayed(context: ActionContext)
}

extension ActionManager {
    public class Scheduler {
        weak var delegate: ActionSchedulerDelegate?

        func schedule(action: Action, delay: Int) {
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(delay)) {
                self.delegate?.onActionDelayed(context: action.context)
            }
        }
    }
}
