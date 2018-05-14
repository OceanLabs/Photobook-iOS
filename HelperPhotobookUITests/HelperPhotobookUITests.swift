//
//  HelperPhotobookUITests.swift
//  HelperPhotobookUITests
//
//  Created by Konstadinos Karayannis on 14/05/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import XCTest

class HelperPhotobookUITests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()
        
        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }
    
    // Not really a test, we need to a grant access to the photo library before the unit tests runs
    func testAllowPhotoLibraryPermission() {
        guard !XCUIApplication().navigationBars["Albums"].exists,
            !XCUIApplication().navigationBars["Stories"].exists
            else {
                return
        }
        
        let accessPhotosButton = XCUIApplication().buttons["accessPhotosButton"]
        wait(for: accessPhotosButton)
        
        if accessPhotosButton.exists {
            accessPhotosButton.tap()
            
            let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
            
            let allowBtn = springboard.buttons["OK"]
            if allowBtn.exists {
                allowBtn.tap()
            }
        }
    }
    
    func wait(for element: XCUIElement) {
        let predicate = NSPredicate(format: "isHittable == 1")
        
        expectation(for: predicate, evaluatedWith: element, handler: nil)
        waitForExpectations(timeout: 60, handler: nil)
    }
    
}
