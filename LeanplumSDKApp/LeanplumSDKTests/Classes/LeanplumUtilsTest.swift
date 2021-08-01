//
//  LeanplumUtilsTest.swift
//  LeanplumSDKTests
//
//

import XCTest

class LeanplumUtilsTest: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        LeanplumHelper.setup_method_swizzling()
        LeanplumHelper.start_production_test()
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        
        let leanplumUtils = LeanplumUtils().leanplumTest()
        XCTAssertTrue(leanplumUtils == "Test leanplum with number = 2")
        XCTAssertFalse(leanplumUtils == "test")
        
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
