//
//  ActionManager+ActionsTrigger.swift
//  Leanplum
//
//  Created by Milos Jakovljevic on 2.01.22.
//  Copyright © 2022 Leanplum. All rights reserved.

import Foundation

extension ActionManager {
    @objc public class ActionsTrigger: NSObject {
        @objc public let eventName: String?
        @objc public let condition: [String]?
        @objc public let contextualValues: LPContextualValues?

        @objc public required init(eventName: String?,
                                   condition: [String]?,
                                   contextualValues: LPContextualValues?) {
            self.eventName = eventName
            self.condition = condition
            self.contextualValues = contextualValues
            super.init()
        }
    }
}
