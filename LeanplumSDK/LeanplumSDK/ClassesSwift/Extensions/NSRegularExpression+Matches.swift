//
//  NSRegularExpression+Matches.swift
//  LeanplumSDK
//
//  Created by Nikola Zagorchev on 19.04.22.
//

import Foundation

extension NSRegularExpression {
    func matches(_ string: String?) -> Bool {
        guard let string = string else {
            return false
        }

        let range = NSRange(location: 0, length: string.utf16.count)
        return firstMatch(in: string, options: [], range: range) != nil
    }
}
