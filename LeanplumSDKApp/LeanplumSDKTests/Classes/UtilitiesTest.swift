//
//  UtilitiesTest.swift
//  LeanplumSDKTests
//
//  Created by Nikola Zagorchev on 21.10.22.
//  Copyright © 2022 Leanplum. All rights reserved.

import Foundation
import XCTest
@testable import Leanplum

class UtilitiesTest: XCTestCase {
    func testSHA256(){
        let strings = [
            // -\:\"fcea8952-0ae1-411d-b23c-50661050ded1\"
            #"-\:\"fcea8952-0ae1-411d-b23c-50661050ded1\""#,
            // abd6039873\",4562412546555904
            #"abd6039873\",4562412546555904"#,
            // !22113163828\""
            #"!22113163828\"""#,
            // "22121327322\",4562412546555904
            // 117669683\""
        #"""
        "22121327322\",4562412546555904"
        117669683\""
        """#,
            // 117669683\""
            #"117669683\"""#,
            "嘁脂Ήᔠ䦐ࠐ䤰†",
            "{{device.hardware_id}}",
            "116115935'2"
        ]
        
        let hashes = [
            "9d68d70f279f830c1e313e813c4b8d672669a8f1a89e87fa268a9a6bc328b704",
            "5b2efdf24962f9c2678f9bb7d30508f499e2be39b928be1986d1eb70190bf2b4",
            "6ca78ed8e23d7851d1d72d90c3b69bcbbbb32dbc8d691d59690d8c444724c372",
            "8bc024a346531a167229f3e431bbec8cba2d73a8d0b0eff6a490e960ace4ddc5",
            "62f3106d53b24f8755c67b49404af3df416f1c889ccf8867bf8eb6fabee82748",
            "5aafde83f3d6a6e8cb35a058976af376fd84311e07a03b03dd9c30dc7c90cc61",
            "03b5c746e38ff7753d8f4854fdaee8cab68d451523e0c534eb00af653816fbc7",
            "68b400b82ffcaea8f34f883c54753a88a09beac0f14518c9aa4d55f21fd103f2"
        ]
        
        for (i, str) in strings.enumerated() {
            XCTAssertEqual(Utilities.sha256(string: str)!, hashes[i])
        }
    }
    
    func testSHA256Normal(){
        let strings = [
            "9d29641dc261454239456122f13de042b3a0cc3f45d4c27e7ddc97b300eb11aa",
            "test@test.com",
            "2ed5184d449e4bbbeef008569a79943c0b3996b1",
            "33a4878d89f77737",
            "CB226263-54C6-4BA9-BA10-CC6D083F9559",
            "032bc2fd2e59449c",
            "744E9F39-EDF1-4460-9C23-DF2827007295",
            "E3311F58_D7BC_4154_8705_C614332E38A1"
        ]
        
        let hashes = [
            "68a971cf29b8b95159a66317a22ab8eaaadae7140b177dd91345d2809ed9b08b",
            "f660ab912ec121d1b1e928a0bb4bc61b15f5ad44d5efdc4e1c92a25e99b8e44a",
            "2849cfc7e464db9e0aafe689f3389de51cd35c44585d6d6183319194deb15c82",
            "64780c16b0a8897d390cb31aa788bd6a8bbbe488cac93d1aff0578746cb70f4b",
            "235fcc26fe5ce4c8f9a307c38aa99f5dbb59f838c81218051c38786ad4d5f162",
            "2ae02aa4705cd42b311f460148491c049d1d1c9e88f04fc2d2653c5b92b2c454",
            "239bcb0aedf9594a9aea2dc59a5e8aba3a5c23cc203890e44a61c4950dab3052",
            "9aa07b6f47bb0e01f5e43037ac1d6fc0b0a779e141fef1db715d3ac9497206f6"
        ]
        
        for (i, str) in strings.enumerated() {
            XCTAssertEqual(Utilities.sha256(string: str)!, hashes[i])
        }
    }
    
    func testSHA256_128(){
        let strings = [
            "9d29641dc261454239456122f13de042b3a0cc3f45d4c27e7ddc97b300eb11aa",
            "test@test.com",
            "CB226263-54C6-4BA9-BA10-CC6D083F9559",
            "E3311F58_D7BC_4154_8705_C614332E38A1"
        ]
        
        let hashes = [
            "68a971cf29b8b95159a66317a22ab8eaaadae7140b177dd91345d2809ed9b08b",
            "f660ab912ec121d1b1e928a0bb4bc61b15f5ad44d5efdc4e1c92a25e99b8e44a",
            "235fcc26fe5ce4c8f9a307c38aa99f5dbb59f838c81218051c38786ad4d5f162",
            "9aa07b6f47bb0e01f5e43037ac1d6fc0b0a779e141fef1db715d3ac9497206f6"
        ]
        
        for (i, str) in strings.enumerated() {
            let hash = Utilities.sha256_200(string: str)!
            XCTAssertEqual(hash.count, 50)
            XCTAssertTrue(hashes[i].contains(hash))
        }
    }
}
