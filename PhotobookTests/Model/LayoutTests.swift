//
//  LayoutTests.swift
//  PhotobookTests
//
//  Created by Jaime Landazuri on 21/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import XCTest
@testable import Photobook

class LayoutTests: XCTestCase {
    
    let validDictionary = ([
        "id": 10,
        "category": "squareCentred"
        ]) as [String: AnyObject]
    
    func testParse_ShouldSucceedWithAValidDictionary() {
        let layout = Layout.parse(validDictionary)
        XCTAssertNotNil(layout, "Parse: Should succeed with a valid dictionary")
    }
    
    func testParse_ShouldReturnNilIfIdIsMissing() {
        var layoutDictionary = validDictionary
        layoutDictionary["id"] = nil
        let layoutBox = Layout.parse(layoutDictionary)
        XCTAssertNil(layoutBox, "Parse: Should return nil if id is missing")
    }

    func testParse_ShouldReturnNilIfCategoryIsMissing() {
        var layoutDictionary = validDictionary
        layoutDictionary["category"] = nil
        let layoutBox = Layout.parse(layoutDictionary)
        XCTAssertNil(layoutBox, "Parse: Should return nil if category is missing")
    }
}
