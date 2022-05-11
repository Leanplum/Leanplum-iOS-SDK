//
//  ActionManager+Configuration.swift
//  LeanplumSDK
//
//  Created by Milos Jakovljevic on 4.5.22..
//

import Foundation
import UIKit


extension ActionManager {
    public class Configuration {
        public let dismissOnPushArrival: Bool
        public let resumeOnEnterForeground: Bool
        
        public init(dismissOnPushArrival: Bool,
                    resumeOnEnterForeground: Bool) {
            self.dismissOnPushArrival = dismissOnPushArrival
            self.resumeOnEnterForeground = resumeOnEnterForeground
        }
    }
}

extension ActionManager.Configuration {
    public static var `default`: ActionManager.Configuration {
        .init(
            dismissOnPushArrival: true,
            resumeOnEnterForeground: true
        )
    }
}
