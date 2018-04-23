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
    
    func testParse_ShouldReturnNilIfIdIsMissing() {
        var layoutDictionary = validDictionary
        layoutDictionary["id"] = nil
        let layoutBox = LayoutBox.parse(layoutDictionary)
        XCTAssertNil(layoutBox, "Parse: Should return nil if ID is missing")
    }
        
    func testParse_ShouldReturnNilIfRectIsMissing() {
        var layoutDictionary = validDictionary
        layoutDictionary["rect"] = nil
        let layoutBox = LayoutBox.parse(layoutDictionary)
        XCTAssertNil(layoutBox, "Parse: Should return nil if rect is missing")
    }

    func testParse_ShouldReturnNilIfXIsNotNormalised() {
        var layoutDictionary = validDictionary
        layoutDictionary["rect"] = [ "x": 12.03, "y": 0.1, "width": 0.1, "height": 0.1 ] as AnyObject
        let layoutBox = LayoutBox.parse(layoutDictionary)
        XCTAssertNil(layoutBox, "Parse: Should return nil if X is not normalised")
    }

    func testParse_ShouldReturnNilIfYIsNotNormalised() {
        var layoutDictionary = validDictionary
        layoutDictionary["rect"] = [ "x": 0.03, "y": 1.01, "width": 0.1, "height": 0.1 ] as AnyObject
        let layoutBox = LayoutBox.parse(layoutDictionary)
        XCTAssertNil(layoutBox, "Parse: Should return nil if Y is not normalised")
    }

    func testParse_ShouldReturnNilIfWidthIsNotNormalised() {
        var layoutDictionary = validDictionary
        layoutDictionary["rect"] = [ "x": 0.03, "y": 0.1, "width": 2.01, "height": 0.1 ] as AnyObject
        let layoutBox = LayoutBox.parse(layoutDictionary)
        XCTAssertNil(layoutBox, "Parse: Should return nil if Width is not normalised")
    }

    func testParse_ShouldReturnNilIfHeightIsNotNormalised() {
        var layoutDictionary = validDictionary
        layoutDictionary["rect"] = [ "x": 0.03, "y": 0.1, "width": 0.01, "height": 4.1 ] as AnyObject
        let layoutBox = LayoutBox.parse(layoutDictionary)
        XCTAssertNil(layoutBox, "Parse: Should return nil if Height is not normalised")
    }
    
    func testIsLandscape_shouldReturnTrue() {
        let layoutBox = LayoutBox(id: 1, rect: CGRect(x: 0.0, y: 0.0, width: 0.9, height: 0.7))
        XCTAssertTrue(layoutBox.isLandscape())
    }

    func testIsLandscape_shouldReturnFalse() {
        let layoutBox = LayoutBox(id: 1, rect: CGRect(x: 0.0, y: 0.0, width: 0.2, height: 0.8))
        XCTAssertFalse(layoutBox.isLandscape())
    }

    func testRectContainedInPageSize() {
        let layoutBox = LayoutBox(id: 1, rect: CGRect(x: 0.05, y: 0.1, width: 0.9, height: 0.8))
        let rect = layoutBox.rectContained(in: CGSize(width: 210.0, height: 152.0))
        XCTAssertTrue(rect ==~ CGRect(x: 10.5, y: 15.2, width: 189.0, height: 121.6))
    }
    
    func testBleedRect_shouldFillContainerIfNil() {
        let layoutBox = LayoutBox(id: 1, rect: CGRect(x: 0.05, y: 0.1, width: 0.9, height: 0.8))
        let bleedRect = layoutBox.bleedRect(in: CGSize(width: 120.0, height: 110.0), withBleed: nil)
        XCTAssertTrue(bleedRect ==~ CGRect(x: 0.0, y: 0.0, width: 120.0, height: 110.0))
    }
    
    func testBleedRect_shouldApplyLeftBleed() {
        let layoutBox = LayoutBox(id: 1, rect: CGRect(x: 0.0, y: 0.1, width: 0.9, height: 0.8))
        let bleedRect = layoutBox.bleedRect(in: CGSize(width: 120.0, height: 110.0), withBleed: 5.0)
        XCTAssertTrue(bleedRect ==~ CGRect(x: -5.0, y: 0.0, width: 125.0, height: 110.0))
    }
    
    func testBleedRect_shouldApplyRightBleed() {
        let layoutBox = LayoutBox(id: 1, rect: CGRect(x: 0.05, y: 0.1, width: 0.95, height: 0.8))
        let bleedRect = layoutBox.bleedRect(in: CGSize(width: 120.0, height: 110.0), withBleed: 5.0)
        XCTAssertTrue(bleedRect ==~ CGRect(x: 0.0, y: 0.0, width: 125.0, height: 110.0))
    }

    func testBleedRect_shouldApplyTopBleed() {
        let layoutBox = LayoutBox(id: 1, rect: CGRect(x: 0.05, y: 0.0, width: 0.9, height: 0.8))
        let bleedRect = layoutBox.bleedRect(in: CGSize(width: 120.0, height: 110.0), withBleed: 5.0)
        XCTAssertTrue(bleedRect ==~ CGRect(x: 0.0, y: -5.0, width: 120.0, height: 115.0))
    }

    func testBleedRect_shouldApplyBottomBleed() {
        let layoutBox = LayoutBox(id: 1, rect: CGRect(x: 0.05, y: 0.1, width: 0.9, height: 0.9))
        let bleedRect = layoutBox.bleedRect(in: CGSize(width: 120.0, height: 110.0), withBleed: 5.0)
        XCTAssertTrue(bleedRect ==~ CGRect(x: 0.0, y: 0.0, width: 120.0, height: 115.0))
    }
    
    func testBleedRect_shouldApplyAllAroundBleed() {
        let layoutBox = LayoutBox(id: 1, rect: CGRect(x: 0.0, y: 0.0, width: 1.0, height: 1.0))
        let bleedRect = layoutBox.bleedRect(in: CGSize(width: 120.0, height: 110.0), withBleed: 5.0)
        XCTAssertTrue(bleedRect ==~ CGRect(x: -5.0, y: -5.0, width: 130.0, height: 120.0))
    }
    
    func testAspecRatioForContainerRatio() {
        let inputs = [
            ( CGSize(width: 1.0, height: 1.0), CGFloat(0.5), CGFloat(0.5) ),
            ( CGSize(width: 0.5, height: 1.0), CGFloat(0.2), CGFloat(0.1) ),
            ( CGSize(width: 1.0, height: 0.5), CGFloat(0.9), CGFloat(1.8) ),
            ( CGSize(width: 0.2, height: 0.3), CGFloat(1.0), CGFloat(0.67) ),
            ( CGSize(width: 0.5, height: 0.1), CGFloat(0.3), CGFloat(1.5) ),
            ( CGSize(width: 1.0, height: 0.1), CGFloat(1.0), CGFloat(10.0) )
        ]
        
        for (index, input) in inputs.enumerated() {
            let layoutBox = LayoutBox(id: 1, rect: CGRect(x: 0.0, y: 0.0, width: input.0.width, height: input.0.height))
            let aspectRatio = layoutBox.aspectRatio(forContainerRatio: input.1)
            XCTAssertTrue(aspectRatio ==~ inputs[index].2, "Result for input ratio \(index + 1) should be \(inputs[index].2), not \(aspectRatio)")
        }
    }
    
    func testContainerSizeForSize() {
        let inputs = [
            ( CGSize(width: 250.0, height: 200.0), CGSize(width: 1000.0, height: 1000.0) ),
            ( CGSize(width: 190.0, height: 150.0), CGSize(width: 760.0, height: 750.0) ),
            ( CGSize(width: 110.0, height: 100.0), CGSize(width: 440.0, height: 500.0) )
            ]

        let layoutBox = LayoutBox(id: 1, rect: CGRect(x: 0.0, y: 0.0, width: 0.25, height: 0.2))

        for (index, input) in inputs.enumerated() {
            let containerSize = layoutBox.containerSize(for: input.0)
            XCTAssertTrue(containerSize ==~ inputs[index].1, "Result for input size \(index + 1) should be \(inputs[index].1), not \(containerSize)")
        }
    }
}
