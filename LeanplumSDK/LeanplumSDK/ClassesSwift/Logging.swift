//
//  Logging.swift
//  LeanplumSDK
//
//  Created by Nikola Zagorchev on 23.12.21.
//  Copyright (c) 2021 Leanplum, Inc. All rights reserved.

/**
 * Swift equivalent of the LPLog C function
 */
enum Log {
    static func info(_ msg: String) {
        LPLogv(.info, msg, getVaList([]))
    }
    
    static func debug(_ msg: String) {
        LPLogv(.debug, msg, getVaList([]))
    }
    
    static func error(_ msg: String) {
        LPLogv(.error, msg, getVaList([]))
    }
}
