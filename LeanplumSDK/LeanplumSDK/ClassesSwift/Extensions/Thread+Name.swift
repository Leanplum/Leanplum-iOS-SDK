//
//  Thread+Name.swift
//  LeanplumSDK
//
//  Created by Nikola Zagorchev on 19.04.23.
//  Copyright © 2023 Leanplum. All rights reserved.

import Foundation

extension Thread {
    var threadName: String {
        if isMainThread {
            return "main"
        } else if let threadName = Thread.current.name, !threadName.isEmpty {
            return threadName
        } else {
            return "background"
        }
    }
}
