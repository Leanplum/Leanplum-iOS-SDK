//
//  ActionManager+Configuration.swift
//  LeanplumSDK
//
//  Created by Milos Jakovljevic on 4.5.22.
//  Copyright © 2022 Leanplum. All rights reserved.

import Foundation
import UIKit

extension ActionManager {
    /// Configuration of the `ActionManager`
    /// - Precondition: set a new `Configuration` to the `ActionManager` with the defined options
    public class Configuration {
        
        /// Keep or dismiss in-app message when push notification is opened. If kept, the action from the
        /// push notification will go into the queue and will be presented after in-app dismissal, otherwise
        /// the in-app is dismissed and the push notification's action is presented.
        ///
        /// If `useAsyncHandlers` is `true`, this configuration will not have any effect and
        /// push notification open will not dismiss the currently shown message.
        ///
        /// - Default value: `true`
        public let dismissOnPushArrival: Bool
        
        /// Message queue is paused when app is backgrounded and resumed when app is foregrounded
        /// Set to `false` to prevent resuming the message queue when app enters foreground
        ///
        /// - Default value: `true`
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
