//
//  Utilities.swift
//  LeanplumSDK
//
//  Created by Nikola Zagorchev on 20.09.21.
//  Copyright © 2021 Leanplum. All rights reserved.

import Foundation
import CommonCrypto

public class Utilities: NSObject {
    /**
     * Returns Leanplum message Id from Notification userInfo.
     * Use this method to identify Leanplum Notifications
     */
    @objc public static func messageIdFromUserInfo(_ userInfo: [AnyHashable: Any]) -> String? {
        if let messageId = userInfo[LP_KEY_PUSH_MESSAGE_ID] ??
            userInfo[LP_KEY_PUSH_MUTE_IN_APP] ??
            userInfo[LP_KEY_PUSH_NO_ACTION] ??
            userInfo[LP_KEY_PUSH_NO_ACTION_MUTE] {
            return String(describing: messageId)
        }
        return nil
    }
    
    @objc public static func sha256(data: Data) -> Data {
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &hash)
        }
        return Data(hash)
    }
    
    @objc public static func sha256(string: String) -> String? {
        guard let messageData = string.data(using: String.Encoding.utf8) else { return nil }
        let hashedData = sha256(data: messageData)
        return hashedData.hexEncodedString()
    }
    
    @objc public static func sha256_200(string: String) -> String? {
        guard let str = sha256(string: string) else { return nil }
        
        let hexLength = 200/4
        return substring(string: str, openEndIndex: hexLength)
    }
    
    @objc public static func sha256_40(string: String) -> String? {
        guard let str = sha256(string: string) else { return nil }
        
        let hexLength = 40/4
        return substring(string: str, openEndIndex: hexLength)
    }
    
    static func substring(string: String, openEndIndex: Int) -> String {
        let endIndex = string.index(string.startIndex, offsetBy: openEndIndex)
        return String(string[..<endIndex])
    }
}
