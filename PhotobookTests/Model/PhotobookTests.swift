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
        "productTemplateId": "RPI_WRAP_210X210_SM",
        "pageHeight": 400.34,
        "spineTextRatio": 0.8,
        "aspectRatio": 1.38,
        "coverLayouts": [ 9, 10 ],
        "layouts": [ 10, 11, 12, 13 ]
    ]) as [String: AnyObject]
    
    func testParse_ShouldSucceedWithAValidDictionary() {
        let photobook = PhotobookTemplate.parse(validDictionary)
        XCTAssertNotNil(photobook, "Parse: Should succeed with a valid dictionary")
    }
    
    func testParse_ShouldReturnNilIfIdIsMissing() {
        var photobookDictionary = validDictionary
        photobookDictionary["id"] = nil
        let photobookBox = PhotobookTemplate.parse(photobookDictionary)
        XCTAssertNil(photobookBox, "Parse: Should return nil if id is missing")
    }

    func testParse_ShouldReturnNilIfNameIsMissing() {
        var photobookDictionary = validDictionary
        photobookDictionary["name"] = nil
        let photobookBox = PhotobookTemplate.parse(photobookDictionary)
        XCTAssertNil(photobookBox, "Parse: Should return nil if name is missing")
    }
    
    // Page Height
    func testParse_ShouldReturnNilIfPageHeightIsMissing() {
        var photobookDictionary = validDictionary
        photobookDictionary["pageHeight"] = nil
        let photobookBox = PhotobookTemplate.parse(photobookDictionary)
        XCTAssertNil(photobookBox, "Parse: Should return nil if pageHeight is missing")
    }
    
    func testParse_ShouldReturnNilIfPageHeightIsZero() {
        var photobookDictionary = validDictionary
        photobookDictionary["pageHeight"] = 0.0 as AnyObject
        let photobookBox = PhotobookTemplate.parse(photobookDictionary)
        XCTAssertNil(photobookBox, "Parse: Should return nil if pageHeight is zero")
    }

    // Spine Ratio
    func testParse_ShouldReturnNilIfSpineRatioIsMissing() {
        var photobookDictionary = validDictionary
        photobookDictionary["spineTextRatio"] = nil
        let photobookBox = PhotobookTemplate.parse(photobookDictionary)
        XCTAssertNil(photobookBox, "Parse: Should return nil if spineTextRatio is missing")
    }
    
    func testParse_ShouldReturnNilIfSpineRatioIsZero() {
        var photobookDictionary = validDictionary
        photobookDictionary["spineTextRatio"] = 0.0 as AnyObject
        let photobookBox = PhotobookTemplate.parse(photobookDictionary)
        XCTAssertNil(photobookBox, "Parse: Should return nil if spineTextRatio is zero")
    }

    // Aspect Ratio
    func testParse_ShouldReturnNilIfAspectRatioIsMissing() {
        var photobookDictionary = validDictionary
        photobookDictionary["aspectRatio"] = nil
        let photobookBox = PhotobookTemplate.parse(photobookDictionary)
        XCTAssertNil(photobookBox, "Parse: Should return nil if aspectRatio is missing")
    }

    func testParse_ShouldReturnNilIfAspectRatioIsZero() {
        var photobookDictionary = validDictionary
        photobookDictionary["aspectRatio"] = 0.0 as AnyObject
        let photobookBox = PhotobookTemplate.parse(photobookDictionary)
        XCTAssertNil(photobookBox, "Parse: Should return nil if aspectRatio is zero")
    }

    // Layouts
    func testParse_ShouldReturnNilIfCoverLayoutsIsMissing() {
        var photobookDictionary = validDictionary
        photobookDictionary["coverLayouts"] = nil
        let photobookBox = PhotobookTemplate.parse(photobookDictionary)
        XCTAssertNil(photobookBox, "Parse: Should return nil if coverLayouts is missing")
    }
    
    func testParse_ShouldReturnNilIfCoverLayoutCountIsZero() {
        var photobookDictionary = validDictionary
        photobookDictionary["coverLayouts"] = [] as AnyObject
        let photobookBox = PhotobookTemplate.parse(photobookDictionary)
        XCTAssertNil(photobookBox, "Parse: Should return nil if the coverLayout count is zero")
    }

    func testParse_ShouldReturnNilIfLayoutsIsMissing() {
        var photobookDictionary = validDictionary
        photobookDictionary["layouts"] = nil
        let photobookBox = PhotobookTemplate.parse(photobookDictionary)
        XCTAssertNil(photobookBox, "Parse: Should return nil if layouts is missing")
    }

    func testParse_ShouldReturnNilIfLayoutCountIsZero() {
        var photobookDictionary = validDictionary
        photobookDictionary["layouts"] = [] as AnyObject
        let photobookBox = PhotobookTemplate.parse(photobookDictionary)
        XCTAssertNil(photobookBox, "Parse: Should return nil if the layout count is zero")
    }

}
