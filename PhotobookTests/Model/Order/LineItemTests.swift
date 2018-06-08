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
        "variant_id": 2,
        "description": "Clown Costume",
        "cost": ["amount": "3.49", "currency": "GBP"],
    ]
    
    func testInit() {
        let id = 4
        let name = "Item number 2"
        let cost: Decimal = 2.49
        let formattedCost = "£2.49"
        
        let lineItem = LineItem(id: id, name: name, cost: cost, formattedCost: formattedCost)
        
        XCTAssertEqual(lineItem.id, id)
        XCTAssertEqual(lineItem.name, name)
        XCTAssertEqual(lineItem.cost, cost)
        XCTAssertEqual(lineItem.formattedCost, formattedCost)
    }
    
    func testParseDetails_shoudParseAValidDictionary() {
        let lineItem = LineItem.parseDetails(dictionary: validDictionary)
        
        XCTAssertEqualOptional(lineItem?.id, 2)
        XCTAssertEqualOptional(lineItem?.name, "Clown Costume")
        XCTAssertEqualOptional(lineItem?.cost, 3.49)
        XCTAssertEqualOptional(lineItem?.formattedCost, "£3.49")
    }
    
    func testParseDetails_shouldFailWithoutAnId() {
        var invalidDictionary = validDictionary
        invalidDictionary["variant_id"] = nil
        
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
        invalidDictionary["cost"] = nil
        
        let lineItem = LineItem.parseDetails(dictionary: invalidDictionary)
        XCTAssertNil(lineItem)
    }

    func testParseDetails_shouldFailWithoutACurrency() {
        var invalidDictionary = validDictionary
        invalidDictionary["cost"] = ["amount": "3.44"]
        
        let lineItem = LineItem.parseDetails(dictionary: invalidDictionary)
        XCTAssertNil(lineItem)
    }

    func testParseDetails_shouldFailWithoutAnAmount() {
        var invalidDictionary = validDictionary
        invalidDictionary["cost"] = ["currency": "GBP"]
        
        let lineItem = LineItem.parseDetails(dictionary: invalidDictionary)
        XCTAssertNil(lineItem)
    }

}
