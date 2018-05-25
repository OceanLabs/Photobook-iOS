//
//  PhotobookPreviewTests.swift
//  SDK DemoUITests
//
//  Created by Konstadinos Karayannis on 25/05/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
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
    
}
