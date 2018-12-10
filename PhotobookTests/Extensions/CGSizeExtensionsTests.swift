//
//  CGSizeExtensionsTests.swift
//  PhotobookTests
//
//  Created by Jaime Landazuri on 29/10/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import XCTest
@testable import Photobook

class CGSizeExtensionsTests: XCTestCase {

    func testResizeAspectFill() {
        let sizes: [(CGSize, CGSize, CGSize)] = [ // Size, Target Size, Expected Result
            (CGSize(width: 10.0, height: 10.0), CGSize(width: 20.0, height: 15.0), CGSize(width: 20.0, height: 20.0)),
            (CGSize(width: 5.0, height: 10.0), CGSize(width: 20.0, height: 15.0), CGSize(width: 20.0, height: 40.0)),
            (CGSize(width: 10.0, height: 10.0), CGSize(width: 20.0, height: 20.0), CGSize(width: 20.0, height: 20.0)),
            (CGSize(width: 10.0, height: 2.0), CGSize(width: 50.0, height: 60.0), CGSize(width: 300.0, height: 60.0)),
            (CGSize(width: 10.0, height: 10.0), CGSize(width: 5.0, height: 10.0), CGSize(width: 10.0, height: 10.0)),
            (CGSize(width: 10.0, height: 10.0), CGSize(width: 5.0, height: 2.0), CGSize(width: 5.0, height: 5.0)),
        ]
        
        for (index, sizeTuple) in sizes.enumerated() {
            let result = sizeTuple.0.resizeAspectFill(sizeTuple.1)
            XCTAssertEqual(sizeTuple.2, result, "Scaled size for \(index + 1) should be \(sizeTuple.2), not \(result)")
        }
    }
    
    func testScalarMultiplicationWithFloat() {
        let size = CGSize(width: 20.0, height: 10.0)
        let scale: CGFloat = 4.0
        XCTAssertEqual(size * scale, CGSize(width: size.width * scale, height: size.height * scale))
        XCTAssertEqual(scale * size, CGSize(width: size.width * scale, height: size.height * scale))
    }
    
    func testScalarMultiplicationWithDouble() {
        let size = CGSize(width: 20.0, height: 10.0)
        let scale = 4.0
        XCTAssertEqual(size * scale, CGSize(width: size.width * CGFloat(scale), height: size.height * CGFloat(scale)))
        XCTAssertEqual(scale * size, CGSize(width: size.width * CGFloat(scale), height: size.height * CGFloat(scale)))
    }

    func testAboutTheSameComparison() {
        XCTAssertTrue(CGSize(width: 10.0, height: 20.0) ==~ CGSize(width: 10.009, height: 19.991))
        XCTAssertFalse(CGSize(width: 10.0, height: 20.0) ==~ CGSize(width: 10.02, height: 19.98))
    }
}
