//
//  XCTestCaseExtensions.swift
//  SDK DemoUITests
//
//  Created by Konstadinos Karayannis on 24/04/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import XCTest

extension XCTestCase {
    
    func wait(_ seconds: TimeInterval) {
        let expectation = self.expectation(description: "Waiting")
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds, execute: {
            expectation.fulfill()
        })
        
        waitForExpectations(timeout: seconds + 1, handler: nil)
    }
    
    func wait(for element: XCUIElement) {
        let predicate = NSPredicate(format: "isHittable == 1")
        
        expectation(for: predicate, evaluatedWith: element, handler: nil)
        waitForExpectations(timeout: 60, handler: nil)
    }
    
}

