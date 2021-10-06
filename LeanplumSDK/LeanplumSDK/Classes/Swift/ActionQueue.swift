//
//  Queue.swift
//  LeanplumSDK
//
//  Created by Milos Jakovljevic on 20.09.21.
//

import Foundation

class ActionQueue {
    typealias L = ActionManager.Action
    
    var queue: [L] = []
    
    func pushBack(_ item: L) {
        queue.append(item)
    }
    
    func pushFront(_ item: L) {
        queue.insert(item, at: 0)
    }
    
    func pop() -> L? {
        if !queue.isEmpty {
            if let index = queue.firstIndex(where: { $0.state != .delayed }) {
                return queue.remove(at: index)
            }
        }
        return nil
    }
    
    func first() -> L? {
        return queue.first
    }
    
    func last() -> L? {
        return queue.last
    }
    
    func empty() -> Bool {
        return queue.isEmpty
    }
}

extension ActionQueue {
    
    func prepareDelayedActions() {
        for var action in queue {
            action.state = .queued
        }
    }
}
