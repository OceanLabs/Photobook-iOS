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
    
    func testParse_shouldSucceedWithAValidDictionary() {
        let layout = Layout.parse(validDictionary)
        XCTAssertNotNil(layout, "Parse: Should succeed with a valid dictionary")
    }
    
    func testParse_shouldReturnNilIfIdIsMissing() {
        var layoutDictionary = validDictionary
        layoutDictionary["id"] = nil
        let layoutBox = Layout.parse(layoutDictionary)
        XCTAssertNil(layoutBox, "Parse: Should return nil if id is missing")
    }
    
    func testParse_shouldReturnNilIfCategoryIsMissing() {
        var layoutDictionary = validDictionary
        layoutDictionary["category"] = nil
        let layoutBox = Layout.parse(layoutDictionary)
        XCTAssertNil(layoutBox, "Parse: Should return nil if category is missing")
    }
    
    func testEquality_shouldBeEqual() {
        let layout1 = Layout(id: 1, category: "Category1", imageLayoutBox: nil, textLayoutBox: nil, isDoubleLayout: false)
        let layout2 = Layout(id: 1, category: "Category1", imageLayoutBox: nil, textLayoutBox: nil, isDoubleLayout: false)
        XCTAssertEqual(layout1, layout2)
    }
    
    func testEquality_shouldNotBeEqual_id() {
        let layout1 = Layout(id: 1, category: "Category1", imageLayoutBox: nil, textLayoutBox: nil, isDoubleLayout: false)
        let layout2 = Layout(id: 2, category: "Category1", imageLayoutBox: nil, textLayoutBox: nil, isDoubleLayout: false)
        XCTAssertNotEqual(layout1, layout2)
    }

    func testEquality_shouldNotBeEqual_category() {
        let layout1 = Layout(id: 1, category: "Category1", imageLayoutBox: nil, textLayoutBox: nil, isDoubleLayout: false)
        let layout2 = Layout(id: 1, category: "Category2", imageLayoutBox: nil, textLayoutBox: nil, isDoubleLayout: false)
        XCTAssertNotEqual(layout1, layout2)
    }
}
