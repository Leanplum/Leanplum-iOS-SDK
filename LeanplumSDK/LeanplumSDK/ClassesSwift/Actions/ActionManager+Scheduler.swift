//
//  ActionManager+Scheduler.swift
//  Leanplum
//
//  Created by Milos Jakovljevic on 2.01.22.
//

import Foundation

extension ActionManager {
    public class Scheduler {
        var actionDelayed: ((Action) -> ())?

        func schedule(action: Action, delay: Int) {
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(delay)) {
                self.actionDelayed?(action)
            }
        }
    }
}
