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
        "id": 0,
        "imageUrl": "/images/layout10.png",
        "layoutBoxes": []
        ]) as [String: AnyObject]
    
    func testParse_ShouldSucceedWithAValidDictionary() {
        let layout = Layout.parse(validDictionary)
        XCTAssertNotNil(layout, "Parse: Should succeed with a valid dictionary")
    }
    
    func testParse_ShouldReturnNifIfIdIsMissing() {
        var layoutDictionary = validDictionary
        layoutDictionary["id"] = nil
        let layoutBox = Layout.parse(layoutDictionary)
        XCTAssertNil(layoutBox, "Parse: Should return nil if id is missing")
    }
    
    func testParse_ShouldReturnNifIfTheImageUrlIsNil() {
        var layoutDictionary = validDictionary
        layoutDictionary["imageUrl"] = nil
        let layoutBox = Layout.parse(layoutDictionary)
        XCTAssertNil(layoutBox, "Parse: Should return nil if imageUrl is missing")
    }
    
    func testParse_ShouldReturnNifIfTheImageUrlIsNotRelative() {
        var layoutDictionary = validDictionary
        layoutDictionary["imageUrl"] = "http://whatever.com/" as AnyObject
        let layoutBox = Layout.parse(layoutDictionary)
        XCTAssertNil(layoutBox, "Parse: Should return nil if imageUrl is not relative")
    }

    func testParse_ShouldAcceptWhitespaces() {
        var layoutDictionary = validDictionary
        layoutDictionary["imageUrl"] = "/whatever here/and there.png" as AnyObject
        let layoutBox = Layout.parse(layoutDictionary)
        XCTAssertNotNil(layoutBox, "Parse: Should succeed if imageUrl contains whitespaces")
    }

    func testParse_ShouldReturnNilIfLayoutBoxesIsMissing() {
        var layoutDictionary = validDictionary
        layoutDictionary["layoutBoxes"] = nil
        let layoutBox = Layout.parse(layoutDictionary)
        XCTAssertNil(layoutBox, "Parse: Should return nil if layoutBoxes is missing")
    }
}
