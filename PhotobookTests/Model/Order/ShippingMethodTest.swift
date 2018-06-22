//
//  ShippingMethodTest.swift
//  PhotobookTests
//
//  Created by Jaime Landazuri on 22/05/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import XCTest
@testable import Photobook

class ShippingMethodTest: XCTestCase {
    
    let validDictionary: [String: Any] = [
        "id": 1,
        "mobile_shipping_name": "Tracked",
        "costs": [["currency": "GBP", "amount": 7.06], ["currency": "EUR", "amount": 8.04], ["currency": "USD", "amount": 9.47]],
        "min_delivery_time": 5,
        "max_delivery_time": 7
    ]
    
    func testInit() {
        let id = 2
        let name = "Tracked"
        let cost = Price(currencyCode: "GBP", value: 7.06)
        let maxDeliveryTime = 7
        let minDeliveryTime = 5
        
        let shippingMethod = ShippingMethod(id: id, name: name, price: cost!, maxDeliveryTime: maxDeliveryTime, minDeliveryTime: minDeliveryTime)
        
        XCTAssertEqual(shippingMethod.id, id)
        XCTAssertEqual(shippingMethod.name, name)
        XCTAssertEqual(shippingMethod.price, cost)
        XCTAssertEqual(shippingMethod.maxDeliveryTime, maxDeliveryTime)
        XCTAssertEqual(shippingMethod.minDeliveryTime, minDeliveryTime)
    }
    
    func testParse_shouldParseAValidDictionary() {
        let shippingMethod = ShippingMethod.parse(dictionary: validDictionary)
        
        XCTAssertEqualOptional(shippingMethod?.id, 1)
        XCTAssertEqualOptional(shippingMethod?.name, "Tracked")
        XCTAssertEqualOptional(shippingMethod?.minDeliveryTime, 5)
        XCTAssertEqualOptional(shippingMethod?.maxDeliveryTime, 7)
    }
    
    func testParse_shouldFailWithNoId() {
        var invalidDictionary = validDictionary
        invalidDictionary["id"] = nil
        
        let shippingMethod = ShippingMethod.parse(dictionary: invalidDictionary)
        XCTAssertNil(shippingMethod)
    }

    func testParse_shouldFailWithNoName() {
        var invalidDictionary = validDictionary
        invalidDictionary["mobile_shipping_name"] = nil
        
        let shippingMethod = ShippingMethod.parse(dictionary: invalidDictionary)
        XCTAssertNil(shippingMethod)
    }
    
    func testParse_shouldFailWithNoCost() {
        var invalidDictionary = validDictionary
        invalidDictionary["costs"] = nil
        
        let shippingMethod = ShippingMethod.parse(dictionary: invalidDictionary)
        XCTAssertNil(shippingMethod)
    }
    
    func testParse_shouldFailWithEmptyCostsArray() {
        var invalidDictionary = validDictionary
        invalidDictionary["costs"] = []
        
        let shippingMethod = ShippingMethod.parse(dictionary: invalidDictionary)
        XCTAssertNil(shippingMethod)
    }
    
    func testParse_shouldFailWithNoCostAmount() {
        var invalidDictionary = validDictionary
        invalidDictionary["costs"] = [["currency": "GBP"]]
        
        let shippingMethod = ShippingMethod.parse(dictionary: invalidDictionary)
        XCTAssertNil(shippingMethod)
    }

    func testParse_shouldFailWithNoCostCurrency() {
        var invalidDictionary = validDictionary
        invalidDictionary["costs"] = [["amount": 3.99]]
        
        let shippingMethod = ShippingMethod.parse(dictionary: invalidDictionary)
        XCTAssertNil(shippingMethod)
    }

    func testParse_shouldFailWithNoMaxDeliveryTime() {
        var invalidDictionary = validDictionary
        invalidDictionary["max_delivery_time"] = nil
        
        let shippingMethod = ShippingMethod.parse(dictionary: invalidDictionary)
        XCTAssertNil(shippingMethod)
    }

    func testParse_shouldFailWithNoMinDeliveryTime() {
        var invalidDictionary = validDictionary
        invalidDictionary["min_delivery_time"] = nil
        
        let shippingMethod = ShippingMethod.parse(dictionary: invalidDictionary)
        XCTAssertNil(shippingMethod)
    }

    func testParse_shouldHaveFreeCostIfValueIsZero() {
        var modifiedDictionary = validDictionary
        modifiedDictionary["costs"] = [["currency": "GBP", "amount": 0.0]]
        
        let shippingMethod = ShippingMethod.parse(dictionary: modifiedDictionary)
        XCTAssertEqualOptional(shippingMethod?.price.formatted, "FREE")
    }
    
    func testDeliveryTime_containsMaxAndMinDeliveryTimes() {
        let shippingMethod = ShippingMethod.parse(dictionary: validDictionary)
        XCTAssertEqualOptional(shippingMethod?.deliveryTime, "5 to 7 working days")
    }
}
