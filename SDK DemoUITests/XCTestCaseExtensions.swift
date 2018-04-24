//
//  XCTestCaseExtensions.swift
//  SDK DemoUITests
//
//  Created by Konstadinos Karayannis on 24/04/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import XCTest

extension XCTestCase {
    
    func wait(for element: XCUIElement) {
        let exists = NSPredicate(format: "isHittable == 1")
        
        expectation(for: exists, evaluatedWith: element, handler: nil)
        waitForExpectations(timeout: 60, handler: nil)
    }
    
    func XCTAssertExists(_ element: XCUIElement) {
        let predicate = NSPredicate(format: "isHittable == 1")
        XCTAssertTrue(predicate.evaluate(with: element))
    }
    
}

