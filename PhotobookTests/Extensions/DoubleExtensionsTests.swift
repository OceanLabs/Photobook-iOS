//
//  DoubleExtensionsTests.swift
//  PhotobookTests
//
//  Created by Jaime Landazuri on 29/10/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import XCTest
@testable import Photobook

class DoubleExtensionsTests: XCTestCase {

    func testIsNormalised_shouldReturnTrue() {
        let doubles = [0.01, 0.1, 0.4, 0.45, 1.0]
        for d in doubles {
            XCTAssertTrue(d.isNormalised)
        }
    }
    
    func testIsNormalised_shouldReturnFalse() {
        XCTAssertFalse((-0.01).isNormalised)
        XCTAssertFalse((1.01).isNormalised)
    }
}
