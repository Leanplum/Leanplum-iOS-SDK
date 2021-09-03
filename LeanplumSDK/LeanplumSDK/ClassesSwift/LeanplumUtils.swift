//
//  LeanplumUtils.swift
//  LeanplumSDK
//
//

import Foundation
//import Leanplum_Private

import Leanplum.Private

struct LPSwift {
    let test1: String
    let test2: Int
}

public class LeanplumUtils: NSObject {
    
    @objc public func leanplumTest() -> String {
//        let _ = LPUtilsPrivate()
        return useStructSwift()
    }
    
    func useStructSwift() -> String {
//        let _ = LPUtilsPrivate()
        let _ = LPTestPrivate()
        let test = LPSwift(test1: "leanplum", test2: 2)
        return "Test \(test.test1) with number = \(test.test2)"
    }
}
