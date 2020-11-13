//
//  FragmentTests.swift
//  FragmentTests
//
//  Created by Cyrus Pellet on 23/08/2020.
//

import XCTest
import UserDefault

class FragmentTests: XCTestCase {
    
    @UserDefault("UserDefaultTest")
    var testString: String?
    
    @UserDefault("UserDefaultTest")
    var testString1: String?
    
    @UserDefault("UserDefaultTestArray")
    var testArray: [String]?
    
    @UserDefault("UserDefaultTestArray")
    var testArray1: [String]?

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        testString = "hello"
        XCTAssert(testString1 == testString)
        testArray = ["A","B","C","D"]
        XCTAssert(testArray == testArray1)
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        measure {
            // Put the code you want to measure the time of here.
        }
    }

}
