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
    
}
