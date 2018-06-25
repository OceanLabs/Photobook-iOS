//
//  LineItemTests.swift
//  PhotobookTests
//
//  Created by Jaime Landazuri on 22/05/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import XCTest
@testable import Photobook

class LineItemTests: XCTestCase {
    
    var validDictionary: [String: Any] = [
        "template_id": "circus_clown1",
        "description": "Clown Costume",
        "product_cost": ["GBP": 21, "EUR": 24.99]
    ]
    
    func testInit() {
        let id = "item_no2"
        let name = "Item number 2"
        let cost = Price(currencyCode: "GBP", value: 21)
        
        let lineItem = LineItem(id: id, name: name, cost: cost!)
        
        XCTAssertEqual(lineItem.id, id)
        XCTAssertEqual(lineItem.name, name)
        XCTAssertEqual(lineItem.cost, cost)
    }
    
    func testParseDetails_shoudParseAValidDictionary() {
        let lineItem = LineItem.parseDetails(dictionary: validDictionary)
        
        let expectedCost = Price(currencyCode: "GBP", value: 21)
        
        XCTAssertEqualOptional(lineItem?.id, "circus_clown1")
        XCTAssertEqualOptional(lineItem?.name, "Clown Costume")
        XCTAssertEqualOptional(lineItem?.cost, expectedCost)
    }
    
    func testParseDetails_shouldFailWithoutAnId() {
        var invalidDictionary = validDictionary
        invalidDictionary["template_id"] = nil
        
        let lineItem = LineItem.parseDetails(dictionary: invalidDictionary)
        XCTAssertNil(lineItem)
    }
    
    func testParseDetails_shouldFailWithoutADescription() {
        var invalidDictionary = validDictionary
        invalidDictionary["description"] = nil
        
        let lineItem = LineItem.parseDetails(dictionary: invalidDictionary)
        XCTAssertNil(lineItem)
    }
    
    func testParseDetails_shouldFailWithoutACost() {
        var invalidDictionary = validDictionary
        invalidDictionary["product_cost"] = nil
        
        let lineItem = LineItem.parseDetails(dictionary: invalidDictionary)
        XCTAssertNil(lineItem)
    }

    func testParseDetails_shouldFailWithInvalidCurrency() {
        var invalidDictionary = validDictionary
        invalidDictionary["product_cost"] = ["FFS": 45]
        
        let lineItem = LineItem.parseDetails(dictionary: invalidDictionary)
        XCTAssertNil(lineItem)
    }

}
