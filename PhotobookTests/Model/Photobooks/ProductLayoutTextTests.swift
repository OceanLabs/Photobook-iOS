//
//  ProductLayoutTextTests.swift
//  PhotobookTests
//
//  Created by Jaime Landazuri on 23/04/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import XCTest
import Photos
@testable import Photobook

class ProductLayoutTextTests: XCTestCase {
    
    func testDeepCopy() {
        let productLayoutText = ProductLayoutText()
        productLayoutText.containerSize = CGSize(width: 200.0, height: 100.0)
        productLayoutText.text = "Text on a page"
        productLayoutText.htmlText = "Text<br /> on a page"
        productLayoutText.fontType = .plain
        
        let productLayoutTextCopy = productLayoutText.deepCopy()
        
        XCTAssertTrue(productLayoutText.containerSize == productLayoutTextCopy.containerSize &&
                    productLayoutText.text == productLayoutTextCopy.text &&
                    productLayoutText.htmlText == productLayoutTextCopy.htmlText &&
                    productLayoutText.fontType == productLayoutTextCopy.fontType)
    }
}
