//
//  CGFloatExtensionsTests.swift
//  PhotobookTests
//
//  Created by Jaime Landazuri on 26/10/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import XCTest
@testable import Photobook

class CGFloatExtensionsTests: XCTestCase {

    func testIsNormalised_shouldReturnTrue() {
        let cgFloats: [CGFloat] = [0.01, 0.1, 0.4, 0.45, 1.0]
        for f in cgFloats {
            XCTAssertTrue(f.isNormalised)
        }
    }

    func testIsNormalised_shouldReturnFalse() {
        XCTAssertFalse((-0.01 as CGFloat).isNormalised)
        XCTAssertFalse((1.01 as CGFloat).isNormalised)
    }
    
    func testInDegrees_shouldReturnTheCorrectAngle() {
        XCTAssertEqual(CGFloat.pi.inDegrees(), 180.0)
        XCTAssertEqual((CGFloat.pi / 2).inDegrees(), 90.0)
        XCTAssertEqual((CGFloat.pi * 3 / 2).inDegrees(), 270.0)
        XCTAssertEqual((CGFloat.pi * 2).inDegrees(), 360.0)
    }
    
    func testAboutTheSameOperator_shouldBeEqual() {
        XCTAssertTrue((0.01 as CGFloat) ==~ 0.01)
        XCTAssertTrue((0.01 as CGFloat) ==~ 0.010009)
        XCTAssertTrue((4.42 as CGFloat) ==~ 4.42001)
        XCTAssertTrue((-0.234 as CGFloat) ==~ -0.2335)
    }
    
    func testAboutTheSameOperator_shouldNotBeEqual() {
        XCTAssertFalse((0.01 as CGFloat) ==~ 0.02)
        XCTAssertFalse((0.01 as CGFloat) ==~ 0.0)
        XCTAssertFalse((1.42 as CGFloat) ==~ 1.409)
        XCTAssertFalse((-0.234 as CGFloat) ==~ -0.223003)
    }
}
