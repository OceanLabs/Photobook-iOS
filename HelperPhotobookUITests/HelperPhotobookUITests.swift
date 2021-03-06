//
//  Modified MIT License
//
//  Copyright (c) 2010-2018 Kite Tech Ltd. https://www.kite.ly
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The software MAY ONLY be used with the Kite Tech Ltd platform and MAY NOT be modified
//  to be used with any competitor platforms. This means the software MAY NOT be modified
//  to place orders with any competitors to Kite Tech Ltd, all orders MUST go through the
//  Kite Tech Ltd platform servers.
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
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
