//
//  LeanplumUtils.swift
//  LeanplumSDK
//
//

import Foundation

struct LPSwift {
    let test1: String
    let test2: Int
}

public class LeanplumUtils: NSObject {
    
    @objc public func leanplumTest() -> String {
        return useStructSwift()
    }
    
    func useStructSwift() -> String {
        let test = LPSwift(test1: "leanplum", test2: 2)
        return "Test \(test.test1) with number = \(test.test2)"
    }
}
