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
    
    var validDictionary = ([
        "id": 1,
        "displayName": "Square 127x127",
        "spineTextRatio": 0.87,
        "coverLayouts": [ 9, 10 ],
        "layouts": [ 10, 11, 12, 13 ],
        "variants": [
            [
                "kiteId": "HDBOOK-127x127",
                "templateId": "hdbook_127x127",
                "minPages": 20,
                "maxPages": 100,
                "coverSize": ["mm": ["height": 127, "width": 129]],
                "size": ["mm": ["height": 121, "width": 216]]
            ]
        ]
    ]) as [String: AnyObject]

    func testParse_shouldSucceedWithAValidDictionary() {
        let photobook = PhotobookTemplate.parse(validDictionary)
        XCTAssertNotNil(photobook, "Parse: Should succeed with a valid dictionary")
    }

    func testParse_shouldReturnNilIfIdIsMissing() {
        var photobookDictionary = validDictionary
        photobookDictionary["id"] = nil
        
        let photobookBox = PhotobookTemplate.parse(photobookDictionary)
        XCTAssertNil(photobookBox, "Parse: Should fail if id is missing")
    }

    func testParse_shouldReturnNilIfKiteIdIsMissing() {
        var photobookDictionary = validDictionary
        
        let invalidVariants = [
            [
                "templateId": "hdbook_127x127",
                "minPages": 20,
                "maxPages": 100,
                "coverSize": ["mm": ["height": 127, "width": 129]],
                "size": ["mm": ["height": 121, "width": 216]]
            ]]
        
        photobookDictionary["variants"] = invalidVariants as AnyObject

        let photobookBox = PhotobookTemplate.parse(photobookDictionary)
        XCTAssertNil(photobookBox, "Parse: Should return nil if kite id is missing")
    }

    func testParse_shouldReturnNilIfNameIsMissing() {
        var photobookDictionary = validDictionary
        photobookDictionary["displayName"] = nil
        let photobookBox = PhotobookTemplate.parse(photobookDictionary)
        XCTAssertNil(photobookBox, "Parse: Should return nil if name is missing")
    }

    // Cover Size
    func testParse_shouldReturnNilIfCoverSizeIsMissing() {
        var photobookDictionary = validDictionary
        
        let invalidVariants = [
            [   "minPages": 20,
                "maxPages": 100,
                "size": ["mm": ["height": 121, "width": 216 ]] ]]
        
        photobookDictionary["variants"] = invalidVariants as AnyObject
        
        let photobookBox = PhotobookTemplate.parse(photobookDictionary)
        XCTAssertNil(photobookBox, "Parse: Should return nil if coverSize is missing")
    }
    
    func testParse_shouldConvertCoverSizeToPoints() {
        let photobook = PhotobookTemplate.parse(validDictionary)
        if let width = photobook?.coverSize.width, let height = photobook?.coverSize.height {
            XCTAssertTrue(width ==~ 365.66)
            XCTAssertTrue(height ==~ 360.0)
        } else {
            XCTFail("Parse: Should parse valid dictionary")
        }
    }

    func testParse_shouldConvertPageSizeAndUseHalfWidth() {
        let photobook = PhotobookTemplate.parse(validDictionary)
        if let width = photobook?.pageSize.width, let height = photobook?.pageSize.height {
            XCTAssertTrue(width ==~ 306.14)
            XCTAssertTrue(height ==~ 342.99)
        } else {
            XCTFail("Parse: Should parse valid dictionary")
        }
    }

    // Page Size
    func testParse_shouldReturnNilIfSizeIsMissing() {
        var photobookDictionary = validDictionary

        let invalidVariants = [
            [   "minPages": 20,
                "maxPages": 100,
                "coverSize": ["mm": ["height": 127, "width": 129 ]] ]]
        
        photobookDictionary["variants"] = invalidVariants as AnyObject
        
        let photobookBox = PhotobookTemplate.parse(photobookDictionary)
        XCTAssertNil(photobookBox, "Parse: Should return nil if pageSize is missing")
    }
    
    // Spine Ratio
    func testParse_shouldReturnNilIfSpineRatioIsMissing() {
        var photobookDictionary = validDictionary
        photobookDictionary["spineTextRatio"] = nil
        let photobookBox = PhotobookTemplate.parse(photobookDictionary)
        XCTAssertNil(photobookBox, "Parse: Should return nil if spineTextRatio is missing")
    }
    
    func testParse_shouldReturnNilIfSpineRatioIsZero() {
        var photobookDictionary = validDictionary
        photobookDictionary["spineTextRatio"] = 0.0 as AnyObject
        let photobookBox = PhotobookTemplate.parse(photobookDictionary)
        XCTAssertNil(photobookBox, "Parse: Should return nil if spineTextRatio is zero")
    }

    // Layouts
    func testParse_shouldReturnNilIfCoverLayoutsIsMissing() {
        var photobookDictionary = validDictionary
        photobookDictionary["coverLayouts"] = nil
        let photobookBox = PhotobookTemplate.parse(photobookDictionary)
        XCTAssertNil(photobookBox, "Parse: Should return nil if coverLayouts is missing")
    }
    
    func testParse_shouldReturnNilIfCoverLayoutCountIsZero() {
        var photobookDictionary = validDictionary
        photobookDictionary["coverLayouts"] = [] as AnyObject
        let photobookBox = PhotobookTemplate.parse(photobookDictionary)
        XCTAssertNil(photobookBox, "Parse: Should return nil if the coverLayout count is zero")
    }

    func testParse_shouldReturnNilIfLayoutsIsMissing() {
        var photobookDictionary = validDictionary
        photobookDictionary["layouts"] = nil
        let photobookBox = PhotobookTemplate.parse(photobookDictionary)
        XCTAssertNil(photobookBox, "Parse: Should return nil if layouts is missing")
    }

    func testParse_shouldReturnNilIfLayoutCountIsZero() {
        var photobookDictionary = validDictionary
        photobookDictionary["layouts"] = [] as AnyObject
        let photobookBox = PhotobookTemplate.parse(photobookDictionary)
        XCTAssertNil(photobookBox, "Parse: Should return nil if the layout count is zero")
    }

}
