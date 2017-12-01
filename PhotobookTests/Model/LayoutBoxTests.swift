//
//  LayoutBoxTests.swift
//  PhotobookTests
//
//  Created by Jaime Landazuri on 21/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import XCTest
@testable import Photobook

class LayoutBoxTests: XCTestCase {
    
    let validDictionary = ([
        "id": 1,
        "rect": [ "x": 0.1, "y": 0.2, "width": 0.01, "height": 0.1 ]
        ]) as [String: AnyObject]

    func testParse_ShouldSucceedWithAValidDictionary() {
        let layoutBox = LayoutBox.parse(validDictionary)
        XCTAssertNotNil(layoutBox, "Parse: Should succeed with a valid dictionary")
    }
    
    func testParse_ShouldReturnNifIfIdIsMissing() {
        var layoutDictionary = validDictionary
        layoutDictionary["id"] = nil
        let layoutBox = LayoutBox.parse(layoutDictionary)
        XCTAssertNil(layoutBox, "Parse: Should return nil if ID is missing")
    }
        
    func testParse_ShouldReturnNifIfRectIsMissing() {
        var layoutDictionary = validDictionary
        layoutDictionary["rect"] = nil
        let layoutBox = LayoutBox.parse(layoutDictionary)
        XCTAssertNil(layoutBox, "Parse: Should return nil if rect is missing")
    }

    func testParse_ShouldReturnNifIfXIsNotNormalised() {
        var layoutDictionary = validDictionary
        layoutDictionary["rect"] = [ "x": 12.03, "y": 0.1, "width": 0.1, "height": 0.1 ] as AnyObject
        let layoutBox = LayoutBox.parse(layoutDictionary)
        XCTAssertNil(layoutBox, "Parse: Should return nil if X is not normalised")
    }

    func testParse_ShouldReturnNifIfYIsNotNormalised() {
        var layoutDictionary = validDictionary
        layoutDictionary["rect"] = [ "x": 0.03, "y": 1.01, "width": 0.1, "height": 0.1 ] as AnyObject
        let layoutBox = LayoutBox.parse(layoutDictionary)
        XCTAssertNil(layoutBox, "Parse: Should return nil if Y is not normalised")
    }

    func testParse_ShouldReturnNifIfWidthIsNotNormalised() {
        var layoutDictionary = validDictionary
        layoutDictionary["rect"] = [ "x": 0.03, "y": 0.1, "width": 2.01, "height": 0.1 ] as AnyObject
        let layoutBox = LayoutBox.parse(layoutDictionary)
        XCTAssertNil(layoutBox, "Parse: Should return nil if Width is not normalised")
    }

    func testParse_ShouldReturnNifIfHeightIsNotNormalised() {
        var layoutDictionary = validDictionary
        layoutDictionary["rect"] = [ "x": 0.03, "y": 0.1, "width": 0.01, "height": 4.1 ] as AnyObject
        let layoutBox = LayoutBox.parse(layoutDictionary)
        XCTAssertNil(layoutBox, "Parse: Should return nil if Height is not normalised")
    }

}
