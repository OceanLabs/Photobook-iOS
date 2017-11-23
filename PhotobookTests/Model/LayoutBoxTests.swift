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
        "contentType": "image",
        "dimensionsPercentages": [ "width": 0.01, "height": 0.1],
        "relativeStartPoint": [ "x": 0.1, "y": 0.2]
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
    
    func testParse_ShouldSucceedIfContentTypeIsText() {
        var layoutDictionary = validDictionary
        layoutDictionary["contentType"] = "text" as AnyObject
        let layoutBox = LayoutBox.parse(layoutDictionary)
        XCTAssertNotNil(layoutBox, "Parse: Should succeed if contentType is text")
    }

    func testParse_ShouldReturnNifIfContentTypeIsNotImageOrText() {
        var layoutDictionary = validDictionary
        layoutDictionary["contentType"] = "pdf" as AnyObject
        let layoutBox = LayoutBox.parse(layoutDictionary)
        XCTAssertNil(layoutBox, "Parse: Should return nil if contenType is not image or text")
    }

    func testParse_ShouldReturnNifIfContentTypeIsMissing() {
        var layoutDictionary = validDictionary
        layoutDictionary["contentType"] = nil
        let layoutBox = LayoutBox.parse(layoutDictionary)
        XCTAssertNil(layoutBox, "Parse: Should return nil if contenType is missing")
    }
    
    func testParse_ShouldReturnNifIfDimensionPercentagesIsMissing() {
        var layoutDictionary = validDictionary
        layoutDictionary["dimensionsPercentages"] = nil
        let layoutBox = LayoutBox.parse(layoutDictionary)
        XCTAssertNil(layoutBox, "Parse: Should return nil if dimensionPercentages is missing")
    }

    func testParse_ShouldReturnNifIfDimensionPercentagesIsNotNormalised() {
        var layoutDictionary = validDictionary
        layoutDictionary["dimensionsPercentages"] = [ "width": 12.03, "height": 33 ] as AnyObject
        let layoutBox = LayoutBox.parse(layoutDictionary)
        XCTAssertNil(layoutBox, "Parse: Should return nil if dimensionPercentages is not normalised")
    }

    func testParse_ShouldReturnNifIfRelativeStartPointIsNotNormalised() {
        var layoutDictionary = validDictionary
        layoutDictionary["relativeStartPoint"] = [ "x": 12.03, "y": 33 ] as AnyObject
        let layoutBox = LayoutBox.parse(layoutDictionary)
        XCTAssertNil(layoutBox, "Parse: Should return nil if relativeStartPoint is not normalised")
    }

    func testParse_ShouldReturnNifIfRelativeStartPointIsMissing() {
        var layoutDictionary = validDictionary
        layoutDictionary["relativeStartPoint"] = nil
        let layoutBox = LayoutBox.parse(layoutDictionary)
        XCTAssertNil(layoutBox, "Parse: Should return nil if relativeStartPoint is missing")
    }

}
