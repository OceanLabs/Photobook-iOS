//
//  DecimalExtensionsTests.swift
//  PhotobookTests
//
//  Created by Jaime Landazuri on 29/10/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import XCTest
@testable import Photobook

class DecimalExtensionsTests: XCTestCase {
    
    func testFormattedCost_withUKLocale() {
        let locale = Locale(identifier: "en_GB")
        let amount: Decimal = 20.99
        let formatted = amount.formattedCost(currencyCode: "GBP", locale: locale)
        XCTAssertEqual(formatted, "£20.99")
    }
    
    func testFormattedCost_withUSLocale() {
        let locale = Locale(identifier: "en_US")
        let amount: Decimal = 20.99
        let formatted = amount.formattedCost(currencyCode: "USD", locale: locale)
        XCTAssertEqual(formatted, "$20.99")
    }
    
    func testFormattedCost_withEULocale() {
        let locale = Locale(identifier: "el_GR")
        let amount: Decimal = 20.99
        let formatted = amount.formattedCost(currencyCode: "EUR", locale: locale)
        XCTAssertEqual(formatted, "20,99 €")
    }
    
    func testAboutTheSameOperator_shouldBeEqual() {
        XCTAssertTrue((0.01 as Decimal) ==~ 0.01)
        XCTAssertTrue((0.01 as Decimal) ==~ 0.010009)
        XCTAssertTrue((4.42 as Decimal) ==~ 4.42001)
        XCTAssertTrue((-0.234 as Decimal) ==~ -0.2335)
    }
    
    func testAboutTheSameOperator_shouldNotBeEqual() {
        XCTAssertFalse((0.01 as Decimal) ==~ 0.02)
        XCTAssertFalse((0.01 as Decimal) ==~ 0.0)
        XCTAssertFalse((1.42 as Decimal) ==~ 1.409)
        XCTAssertFalse((-0.234 as Decimal) ==~ -0.223003)
    }
}
