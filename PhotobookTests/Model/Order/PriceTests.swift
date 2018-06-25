//
//  PriceTests.swift
//  PhotobookTests
//
//  Created by Julian Gruber on 22/06/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import XCTest
@testable import Photobook

class PriceTests: XCTestCase {
    
    let validDictionary: [String: Any] = [
        "GBP": 21.5,
        "EUR": 25.0
    ]
    
    let validDictionaries: [[String: Any]] = [
        ["currency": "GBP", "amount": 21.5],
        ["currency": "EUR", "amount": 25.0],
        ["currency": "USD", "amount": 29.0]
    ]
    
    func testInit() {
        let currencyCode = "GBP"
        let value: Decimal = 12.2
        let price = Price(currencyCode: currencyCode, value: value)
        
        XCTAssertNotNil(price)
        XCTAssertEqualOptional(price?.currencyCode, currencyCode)
        XCTAssertEqualOptional(price?.value, value)
        XCTAssertEqualOptional(price?.formatted, "£12.20")
    }

    func testParseDictionary_withValidDictionary() {
        let price = Price.parse(validDictionary, localeCurrencyCode: "GBP")
        
        XCTAssertNotNil(price)
        XCTAssertEqualOptional(price?.currencyCode, "GBP")
        XCTAssertEqualOptional(price?.value, 21.5)
        XCTAssertEqualOptional(price?.formatted, "£21.50")
    }
    
    func testParseDictionary_withEmptyDictionary() {
        
        var invalidDictionary = validDictionary
        invalidDictionary.removeAll()
        
        let price = Price.parse(invalidDictionary)
        
        XCTAssertNil(price)
    }
    
    func testParseDictionaries_withValidDictionaries() {
        let price = Price.parse(validDictionaries, localeCurrencyCode: "GBP")
        
        XCTAssertNotNil(price)
        XCTAssertEqualOptional(price?.currencyCode, "GBP")
        XCTAssertEqualOptional(price?.value, 21.5)
        XCTAssertEqualOptional(price?.formatted, "£21.50")
    }
    
    func testParseDictionaries_withEmptyDictionaries() {
        
        var invalidDictionaries = validDictionaries
        invalidDictionaries.removeAll()
        
        let price = Price.parse(invalidDictionaries)
        
        XCTAssertNil(price)
    }
    
}
