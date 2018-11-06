//
//  AnalyticsTests.swift
//  PhotobookTests
//
//  Created by Jaime Landazuri on 26/10/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import XCTest
@testable import Photobook

class AnalyticsTests: XCTestCase {
    
    let sut = Analytics()
    
    func testUserDistinctId_returnsAnId() {
        XCTAssertNotNil(sut.userDistinctId)
    }
    
    func testUserDistinctId_returnsSameIdForTheDevice() {
        let sut2 = Analytics()
        XCTAssertEqual(sut.userDistinctId, sut2.userDistinctId)
    }

}
