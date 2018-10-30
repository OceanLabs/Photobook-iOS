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

class PhotobookPreviewTests: PhotobookUITest {
    
    func testSizeChange() {
        automation.goToPhotobookReview()
        
        let titleButton = automation.app.buttons["titleButton"]
        let originalTitle = titleButton.label
            
        titleButton.tap()
        
        let sizeButton = automation.app.sheets.buttons.matching(NSPredicate(format: "label != \"Cancel\" && label != \"\(originalTitle)\"")).firstMatch
        sizeButton.tap()
        
        XCTAssertNotEqual(titleButton.label, originalTitle)
    }
    
    func testEnterTextOnSpine() {
        automation.goToPhotobookReview()
        
        let spineLabel = automation.app.staticTexts["spineLabel"]
        XCTAssertTrue(spineLabel.label.isEmpty, "The spine label should be empty at the beginning")
        
        let spineButton = automation.app.collectionViews/*@START_MENU_TOKEN@*/.otherElements["spineButton"]/*[[".cells",".otherElements[\"Spine\"]",".otherElements[\"spineButton\"]"],[[[-1,2],[-1,1],[-1,0,1]],[[-1,2],[-1,1]]],[0]]@END_MENU_TOKEN@*/
        spineButton.tap()
        
        let spineTextField = automation.app.textFields["spineTextField"]
        spineTextField.typeText("The Story of the Grand Clown Fiesta\n")
        
        XCTAssertTrue(spineButton.isHittable, "Did not return to Photobook preview")
        XCTAssertEqual(spineLabel.label, "The Story of the Grand Clown Fiesta")
    }
    
    func testRearrange() {
        automation.goToPhotobookReview()
        
        automation.app.navigationBars.firstMatch.buttons["Rearrange"].tap()
        
        automation.app.collectionViews.otherElements["Pages 2 and 3"].tap()
        automation.app.menuItems["Copy"].tap()
        
        wait(0.5) // Wait for the menu to animate away
        
        automation.app.collectionViews.otherElements["Pages 2 and 3"].tap()
        automation.app.menuItems["Paste"].tap()
        
        wait(0.5) // Wait for the insertion animation
        
        automation.app.collectionViews.firstMatch.swipeUp()
        automation.app.collectionViews.firstMatch.swipeUp()
        
        XCTAssertTrue(automation.app.collectionViews.otherElements["Pages 20 and 21"].exists)
        automation.app.collectionViews.otherElements["Pages 20 and 21"].tap()
        automation.app.menuItems["Delete"].tap()
        
        wait(0.5) // Wait for the menu to animate away
        XCTAssertFalse(automation.app.collectionViews.otherElements["Pages 20 and 21"].exists)
    }
    
    func testAddPages() {
        automation.goToPhotobookReview()
        
        automation.app.navigationBars.firstMatch.buttons["Rearrange"].tap()
        
        automation.app.collectionViews.buttons["Add pages after page 1"].tap()
        
        wait(0.5) // Wait for the insertion animation
        
        automation.app.collectionViews.firstMatch.swipeUp()
        automation.app.collectionViews.firstMatch.swipeUp()
    }
    
}
