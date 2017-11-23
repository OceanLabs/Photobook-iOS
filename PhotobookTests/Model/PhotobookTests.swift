//
//  PhotobookTests.swift
//  PhotobookTests
//
//  Created by Jaime Landazuri on 21/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import XCTest
@testable import Photobook

class PhotobookTests: XCTestCase {
    
    let validDictionary = ([
        "id": 10,
        "name": "210 x 210",
        "pageWidth": 1000,
        "pageHeight": 400,
        "coverWidth": 1030,
        "coverHeight": 415,
        "cost": [ "EUR": 10.00 as Decimal, "USD": 12.00 as Decimal, "GBP": 9.00 as Decimal ],
        "costPerPage": [ "EUR": 1.00 as Decimal, "USD": 1.20 as Decimal, "GBP": 0.85 as Decimal ],
        "coverLayouts": [ 9, 10 ],
        "layouts": [ 10, 11, 12, 13 ]
    ]) as [String: AnyObject]
    
    func testParse_ShouldSucceedWithAValidDictionary() {
        let photobook = Photobook.parse(validDictionary)
        XCTAssertNotNil(photobook, "Parse: Should succeed with a valid dictionary")
    }
    
    func testParse_ShouldReturnNifIfIdIsMissing() {
        var photobookDictionary = validDictionary
        photobookDictionary["id"] = nil
        let photobookBox = Photobook.parse(photobookDictionary)
        XCTAssertNil(photobookBox, "Parse: Should return nil if id is missing")
    }

    func testParse_ShouldReturnNifIfNameIsMissing() {
        var photobookDictionary = validDictionary
        photobookDictionary["name"] = nil
        let photobookBox = Photobook.parse(photobookDictionary)
        XCTAssertNil(photobookBox, "Parse: Should return nil if name is missing")
    }
    
    // PageWidth
    func testParse_ShouldReturnNifIfPageWidthIsMissing() {
        var photobookDictionary = validDictionary
        photobookDictionary["pageWidth"] = nil
        let photobookBox = Photobook.parse(photobookDictionary)
        XCTAssertNil(photobookBox, "Parse: Should return nil if pageWidth is missing")
    }

    func testParse_ShouldReturnNifIfPageWidthIsZero() {
        var photobookDictionary = validDictionary
        photobookDictionary["pageWidth"] = 0.0 as AnyObject
        let photobookBox = Photobook.parse(photobookDictionary)
        XCTAssertNil(photobookBox, "Parse: Should return nil if pageWidth is zero")
    }

    // PageHeight
    func testParse_ShouldReturnNifIfPageHeightIsMissing() {
        var photobookDictionary = validDictionary
        photobookDictionary["pageHeight"] = nil
        let photobookBox = Photobook.parse(photobookDictionary)
        XCTAssertNil(photobookBox, "Parse: Should return nil if pageHeight is missing")
    }
    
    func testParse_ShouldReturnNifIfPageHeightIsZero() {
        var photobookDictionary = validDictionary
        photobookDictionary["pageHeight"] = 0.0 as AnyObject
        let photobookBox = Photobook.parse(photobookDictionary)
        XCTAssertNil(photobookBox, "Parse: Should return nil if pageHeight is zero")
    }

    // CoverWidth
    func testParse_ShouldReturnNifIfCoverWidthIsMissing() {
        var photobookDictionary = validDictionary
        photobookDictionary["coverWidth"] = nil
        let photobookBox = Photobook.parse(photobookDictionary)
        XCTAssertNil(photobookBox, "Parse: Should return nil if coverWidth is missing")
    }
    
    func testParse_ShouldReturnNifIfCoverWidthIsZero() {
        var photobookDictionary = validDictionary
        photobookDictionary["coverWidth"] = 0.0 as AnyObject
        let photobookBox = Photobook.parse(photobookDictionary)
        XCTAssertNil(photobookBox, "Parse: Should return nil if coverWidth is zero")
    }
    
    // CoverHeight
    func testParse_ShouldReturnNifIfCoverHeightIsMissing() {
        var photobookDictionary = validDictionary
        photobookDictionary["coverHeight"] = nil
        let photobookBox = Photobook.parse(photobookDictionary)
        XCTAssertNil(photobookBox, "Parse: Should return nil if coverHeight is missing")
    }
    
    func testParse_ShouldReturnNifIfCoverHeightIsZero() {
        var photobookDictionary = validDictionary
        photobookDictionary["coverHeight"] = 0.0 as AnyObject
        let photobookBox = Photobook.parse(photobookDictionary)
        XCTAssertNil(photobookBox, "Parse: Should return nil if coverHeight is zero")
    }
    
    // Base cost & Page cost
    func testParse_ShouldReturnNifIfCostIsMissing() {
        var photobookDictionary = validDictionary
        photobookDictionary["cost"] = nil
        let photobookBox = Photobook.parse(photobookDictionary)
        XCTAssertNil(photobookBox, "Parse: Should return nil if cost is missing")
    }

    func testParse_ShouldReturnNifIfCostPerPageIsMissing() {
        var photobookDictionary = validDictionary
        photobookDictionary["costPerPage"] = nil
        let photobookBox = Photobook.parse(photobookDictionary)
        XCTAssertNil(photobookBox, "Parse: Should return nil if cost per page is missing")
    }

    // Layouts
    func testParse_ShouldReturnNifIfCoverLayoutsIsMissing() {
        var photobookDictionary = validDictionary
        photobookDictionary["coverLayouts"] = nil
        let photobookBox = Photobook.parse(photobookDictionary)
        XCTAssertNil(photobookBox, "Parse: Should return nil if coverLayouts is missing")
    }
    
    func testParse_ShouldReturnNifIfCoverLayoutCountIsZero() {
        var photobookDictionary = validDictionary
        photobookDictionary["coverLayouts"] = [] as AnyObject
        let photobookBox = Photobook.parse(photobookDictionary)
        XCTAssertNil(photobookBox, "Parse: Should return nil if the coverLayout count is zero")
    }

    func testParse_ShouldReturnNifIfLayoutsIsMissing() {
        var photobookDictionary = validDictionary
        photobookDictionary["layouts"] = nil
        let photobookBox = Photobook.parse(photobookDictionary)
        XCTAssertNil(photobookBox, "Parse: Should return nil if layouts is missing")
    }

    func testParse_ShouldReturnNifIfLayoutCountIsZero() {
        var photobookDictionary = validDictionary
        photobookDictionary["layouts"] = [] as AnyObject
        let photobookBox = Photobook.parse(photobookDictionary)
        XCTAssertNil(photobookBox, "Parse: Should return nil if the layout count is zero")
    }

}
