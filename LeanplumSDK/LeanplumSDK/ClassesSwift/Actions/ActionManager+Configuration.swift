//
//  ActionManager+Configuration.swift
//  LeanplumSDK
//
//  Created by Milos Jakovljevic on 4.5.22.
//  Copyright © 2022 Leanplum. All rights reserved.

import Foundation
import UIKit


extension ActionManager {
    public class Configuration {
        public let dismissOnPushArrival: Bool
        public let resumeOnEnterForeground: Bool
        public let triggerOneAction: Bool
        
        public init(dismissOnPushArrival: Bool,
                    resumeOnEnterForeground: Bool,
                    triggerOneAction: Bool) {
            self.dismissOnPushArrival = dismissOnPushArrival
            self.resumeOnEnterForeground = resumeOnEnterForeground
            self.triggerOneAction = triggerOneAction
        }
    }
}

extension ActionManager.Configuration {
    public static var `default`: ActionManager.Configuration {
        .init(
            dismissOnPushArrival: true,
            resumeOnEnterForeground: true,
            triggerOneAction: true
        )
    }
}
