//
//  ActionManager+Queue.swift
//  Leanplum
//
//  Created by Milos Jakovljevic on 2.01.22.
//  Copyright © 2022 Leanplum. All rights reserved.

import Foundation

extension ActionManager {
    final class Queue {
        let lock = DispatchQueue(label: "leanplum.access_dispatch_queue", attributes: .concurrent)
        var queue: [Action] = []
        
        func pushBack(_ item: Action) {
            lock.async(flags: .barrier) {
                self.queue.append(item)
            }
        }

        func pushFront(_ item: Action) {
            lock.async(flags: .barrier) {
                self.queue.insert(item, at: 0)
            }
        }

        func pop() -> Action? {
            return lock.sync {
                if !queue.isEmpty {
                    return queue.remove(at: 0)
                }
                return nil
            }
        }

        func first() -> Action? {
            return lock.sync {
                return queue.first
            }
        }

        func last() -> Action? {
            return lock.sync {
                return queue.last
            }
        }

        func empty() -> Bool {
            return lock.sync {
                queue.isEmpty
            }
        }

        func count() -> Int {
            return lock.sync {
                queue.count
            }
        }
        
        func popAll() -> [Action] {
            return lock.sync {
                var all = [Action]()
                while let action = pop() {
                    all.append(action)
                }
                return all
            }
        }
    }
}
