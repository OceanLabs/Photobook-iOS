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
        "name": "Express Delivery",
        "shipping_cost": ["amount": "3.99", "currency": "GBP"],
        "total_order_cost": ["amount": "20.45", "currency": "GBP"],
        "deliver_time": ["max_days": 6, "min_days": 2]
    ]

    func testInit() {
        let id = 2
        let name = "Standard Class"
        let shippingCostFormatted = "£3.99"
        let totalCost: Decimal = 20.45
        let totalCostFormatted = "£20.45"
        let maxDeliveryTime = 6
        let minDeliveryTime = 2
        
        let shippingMethod = ShippingMethod(id: id, name: name, shippingCostFormatted: shippingCostFormatted, totalCost: totalCost, totalCostFormatted: totalCostFormatted, maxDeliveryTime: maxDeliveryTime, minDeliveryTime: minDeliveryTime)
        
        XCTAssertEqual(shippingMethod.id, id)
        XCTAssertEqual(shippingMethod.name, name)
        XCTAssertEqual(shippingMethod.shippingCostFormatted, shippingCostFormatted)
        XCTAssertEqual(shippingMethod.totalCost, totalCost)
        XCTAssertEqual(shippingMethod.totalCostFormatted, totalCostFormatted)
        XCTAssertEqual(shippingMethod.maxDeliveryTime, maxDeliveryTime)
        XCTAssertEqual(shippingMethod.minDeliveryTime, minDeliveryTime)
    }
    
    func testParse_shouldParseAValidDictionary() {
        let shippingMethod = ShippingMethod.parse(dictionary: validDictionary)
        
        XCTAssertEqualOptional(shippingMethod?.id, 1)
        XCTAssertEqualOptional(shippingMethod?.name, "Express Delivery")
        XCTAssertEqualOptional(shippingMethod?.shippingCostFormatted, "£3.99")
        XCTAssertEqualOptional(shippingMethod?.totalCost, 20.45)
        XCTAssertEqualOptional(shippingMethod?.totalCostFormatted, "£20.45")
        XCTAssertEqualOptional(shippingMethod?.minDeliveryTime, 2)
        XCTAssertEqualOptional(shippingMethod?.maxDeliveryTime, 6)
    }
    
    func testParse_shouldFailWithNoId() {
        var invalidDictionary = validDictionary
        invalidDictionary["id"] = nil
        
        let shippingMethod = ShippingMethod.parse(dictionary: invalidDictionary)
        XCTAssertNil(shippingMethod)
    }

    func testParse_shouldFailWithNoName() {
        var invalidDictionary = validDictionary
        invalidDictionary["name"] = nil
        
        let shippingMethod = ShippingMethod.parse(dictionary: invalidDictionary)
        XCTAssertNil(shippingMethod)
    }
    
    func testParse_shouldFailWithNoShippingCost() {
        var invalidDictionary = validDictionary
        invalidDictionary["shipping_cost"] = nil
        
        let shippingMethod = ShippingMethod.parse(dictionary: invalidDictionary)
        XCTAssertNil(shippingMethod)
    }
    
    func testParse_shouldFailWithNoShippingCostAmount() {
        var invalidDictionary = validDictionary
        invalidDictionary["shipping_cost"] = ["currency": "GBP"]
        
        let shippingMethod = ShippingMethod.parse(dictionary: invalidDictionary)
        XCTAssertNil(shippingMethod)
    }

    func testParse_shouldFailWithNoShippingCostCurrency() {
        var invalidDictionary = validDictionary
        invalidDictionary["shipping_cost"] = ["amount": "3.99"]
        
        let shippingMethod = ShippingMethod.parse(dictionary: invalidDictionary)
        XCTAssertNil(shippingMethod)
    }

    func testParse_shouldFailWithNoTotalCost() {
        var invalidDictionary = validDictionary
        invalidDictionary["total_order_cost"] = nil
        
        let shippingMethod = ShippingMethod.parse(dictionary: invalidDictionary)
        XCTAssertNil(shippingMethod)
    }
    
    func testParse_shouldFailWithNoTotalCostAmount() {
        var invalidDictionary = validDictionary
        invalidDictionary["total_order_cost"] = ["currency": "GBP"]
        
        let shippingMethod = ShippingMethod.parse(dictionary: invalidDictionary)
        XCTAssertNil(shippingMethod)
    }
    
    func testParse_shouldFailWithNoTotalCostCurrency() {
        var invalidDictionary = validDictionary
        invalidDictionary["total_order_cost"] = ["amount": "20.45"]
        
        let shippingMethod = ShippingMethod.parse(dictionary: invalidDictionary)
        XCTAssertNil(shippingMethod)
    }

    func testParse_shouldFailWithNoDeliverTime() {
        var invalidDictionary = validDictionary
        invalidDictionary["deliver_time"] = nil
        
        let shippingMethod = ShippingMethod.parse(dictionary: invalidDictionary)
        XCTAssertNil(shippingMethod)
    }

    func testParse_shouldFailWithNoMaxDays() {
        var invalidDictionary = validDictionary
        invalidDictionary["deliver_time"] = ["min_days": 1]
        
        let shippingMethod = ShippingMethod.parse(dictionary: invalidDictionary)
        XCTAssertNil(shippingMethod)
    }

    func testParse_shouldFailWithNoMinDays() {
        var invalidDictionary = validDictionary
        invalidDictionary["deliver_time"] = ["max_days": 6]
        
        let shippingMethod = ShippingMethod.parse(dictionary: invalidDictionary)
        XCTAssertNil(shippingMethod)
    }

    func testParse_shouldHaveFreeCostIfValueIsZero() {
        var modifiedDictionary = validDictionary
        modifiedDictionary["shipping_cost"] = ["amount": "0", "currency": "GBP"]
        
        let shippingMethod = ShippingMethod.parse(dictionary: modifiedDictionary)
        XCTAssertEqualOptional(shippingMethod?.shippingCostFormatted, "FREE")
    }
    
    func testDeliveryTime_containsMaxAndMinDeliveryTimes() {
        let shippingMethod = ShippingMethod.parse(dictionary: validDictionary)
        XCTAssertEqualOptional(shippingMethod?.deliveryTime, "2 to 6 working days")
    }
}
