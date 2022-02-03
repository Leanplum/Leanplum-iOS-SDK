//
//  ActionManager+Queue.swift
//  Leanplum
//
//  Created by Milos Jakovljevic on 2.01.22.
//

import Foundation

extension ActionManager {
    final class Queue {
        let lock = DispatchSemaphore(value: 1)
        var queue: [Action] = []

        func pushBack(_ item: Action) {
            lock.with {
                queue.append(item)
            }
        }

        func pushFront(_ item: Action) {
            lock.with {
                queue.insert(item, at: 0)
            }
        }

        func pop() -> Action? {
            return lock.with {
                if !queue.isEmpty {
                    if let index = queue.firstIndex(where: { $0.state != .delayed }) {
                        return queue.remove(at: index)
                    }
                }
                return nil
            }
        }

        func first() -> Action? {
            return lock.with {
                return queue.first
            }
        }

        func last() -> Action? {
            return lock.with {
                return queue.last
            }
        }

        func empty() -> Bool {
            return lock.with {
                queue.isEmpty
            }
        }

        func count() -> Int {
            return lock.with {
                queue.count
            }
        }

        func prepareActions(to state: Action.State = .delayed) {
            lock.with {
                for var action in queue {
                    action.state = state
                }
            }
        }
    }
}

private extension DispatchSemaphore {
    @discardableResult
    func with<T>(_ block: () throws -> T) rethrows -> T {
        wait()
        defer { signal() }
        return try block()
    }
}
