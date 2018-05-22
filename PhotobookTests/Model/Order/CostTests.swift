//
//  CostTests.swift
//  PhotobookTests
//
//  Created by Jaime Landazuri on 22/05/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import XCTest
@testable import Photobook

class CostTests: XCTestCase {
    
    let validDictionary: [String: Any] = [
        "line_items": [
            ["variant_id": 1,
             "description": "Line Item",
             "cost": ["amount": "30.0", "currency": "GBP"]]
        ],
        "shipping_methods": [
            ["id": 3,
             "name": "standard",
             "shipping_cost": ["amount": "2", "currency": "GBP"],
             "total_order_cost": ["amount": "30", "currency": "GBP"],
             "deliver_time": ["max_days": 30, "min_days": 4]],
            ["id": 4,
             "name": "express",
             "shipping_cost": ["amount": "10", "currency": "GBP"],
             "total_order_cost": ["amount": "38", "currency": "GBP"],
             "deliver_time": ["max_days": 2, "min_days": 1]]
        ],
        "promo_code": [
            "discount": ["amount": "1.5", "currency": "GBP"]
        ]
    ]
    
    func testInit() {
        let hash = 233
        let lineItems = [LineItem(id: 1, name: "item", cost: 3.0, formattedCost: "3")]
        let shippingMethods = [ShippingMethod(id: 1, name: "shipping", shippingCostFormatted: "£5.99", totalCost: 20.4, totalCostFormatted: "£20.40", maxDeliveryTime: 30, minDeliveryTime: 4)]
        let promoDiscount = "discount"
        let promoCodeInvalidReason = "reason"
        
        let cost = Cost(hash: hash, lineItems: lineItems, shippingMethods: shippingMethods, promoDiscount: promoDiscount, promoCodeInvalidReason: promoCodeInvalidReason)
        
        XCTAssertEqual(cost.orderHash, 233)
        XCTAssertEqualOptional(cost.lineItems?.first?.id, 1)
        XCTAssertEqualOptional(cost.lineItems?.first?.name, "item")
        XCTAssertEqualOptional(cost.lineItems?.first?.cost, 3)
        XCTAssertEqualOptional(cost.lineItems?.first?.formattedCost, "3")
        XCTAssertEqualOptional(cost.shippingMethods?.first?.id, 1)
        XCTAssertEqualOptional(cost.shippingMethods?.first?.name, "shipping")
        XCTAssertEqualOptional(cost.shippingMethods?.first?.shippingCostFormatted, "£5.99")
        XCTAssertEqualOptional(cost.shippingMethods?.first?.totalCost, 20.4)
        XCTAssertEqualOptional(cost.shippingMethods?.first?.totalCostFormatted, "£20.40")
        XCTAssertEqualOptional(cost.shippingMethods?.first?.maxDeliveryTime, 30)
        XCTAssertEqualOptional(cost.shippingMethods?.first?.minDeliveryTime, 4)
        XCTAssertEqualOptional(cost.promoDiscount, "discount")
        XCTAssertEqualOptional(cost.promoCodeInvalidReason, "reason")
    }
 
    func testShippingMethod_shouldBeNilIfShippingMethodIsNil() {
        let hash = 1
        
        let shippingMethods = [
            ShippingMethod(id: 1, name: "shipping1", shippingCostFormatted: "£2.99", totalCost: 20.4, totalCostFormatted: "£2.40", maxDeliveryTime: 20, minDeliveryTime: 4),
            ShippingMethod(id: 2, name: "shipping2", shippingCostFormatted: "£5.99", totalCost: 30.4, totalCostFormatted: "£3.40", maxDeliveryTime: 40, minDeliveryTime: 8)
        ]

        let cost = Cost(hash: hash, lineItems: nil, shippingMethods: shippingMethods, promoDiscount: nil, promoCodeInvalidReason: nil)
        
        let shippingMethod = cost.shippingMethod(id: nil)
        
        XCTAssertNil(shippingMethod)
    }
    
    func testShippingMethod_shouldBeNilIfTheListOfShippingMethodsIsNil() {
        let hash = 1
        let cost = Cost(hash: hash, lineItems: nil, shippingMethods: nil, promoDiscount: nil, promoCodeInvalidReason: nil)
        
        let shippingMethod = cost.shippingMethod(id: 1)
        
        XCTAssertNil(shippingMethod)
    }
    
    func testShippingMethod_shouldBeNilIfTheListOfShippingMethodsIsEmpty() {
        let hash = 1
        let cost = Cost(hash: hash, lineItems: nil, shippingMethods: [], promoDiscount: nil, promoCodeInvalidReason: nil)
        
        let shippingMethod = cost.shippingMethod(id: 1)
        
        XCTAssertNil(shippingMethod)
    }
    
    func testShippingMethod_shouldReturnTheRightShippingMethod() {
        let hash = 1
        
        let shippingMethods = [
            ShippingMethod(id: 1, name: "shipping1", shippingCostFormatted: "£2.99", totalCost: 20.4, totalCostFormatted: "£2.40", maxDeliveryTime: 20, minDeliveryTime: 4),
            ShippingMethod(id: 2, name: "shipping2", shippingCostFormatted: "£5.99", totalCost: 30.4, totalCostFormatted: "£3.40", maxDeliveryTime: 40, minDeliveryTime: 8),
            ShippingMethod(id: 3, name: "shipping3", shippingCostFormatted: "£7.99", totalCost: 30.4, totalCostFormatted: "£3.40", maxDeliveryTime: 50, minDeliveryTime: 8),
            ShippingMethod(id: 4, name: "shipping4", shippingCostFormatted: "£9.99", totalCost: 30.4, totalCostFormatted: "£3.40", maxDeliveryTime: 60, minDeliveryTime: 8),
            ]
        
        let cost = Cost(hash: hash, lineItems: nil, shippingMethods: shippingMethods, promoDiscount: nil, promoCodeInvalidReason: nil)
        
        let shippingMethod = cost.shippingMethod(id: 3)
        
        XCTAssertEqualOptional(shippingMethod?.id, 3)
        XCTAssertEqualOptional(shippingMethod?.name, "shipping3")
    }

    func testParseDetails_shoudParseAValidDictionary() {
        let cost = Cost.parseDetails(dictionary: validDictionary)
        
        XCTAssertEqualOptional(cost?.lineItems?.count, 1)
        XCTAssertEqualOptional(cost?.shippingMethods?.count, 2)
        XCTAssertEqualOptional(cost?.promoDiscount, "£1.50")
    }
    
    func testParseDetails_shouldFailIfLineItemsAreMissing() {
        var invalidDictionary = validDictionary
        invalidDictionary["line_items"] = nil
        
        let cost = Cost.parseDetails(dictionary: invalidDictionary)
        XCTAssertNil(cost)
    }
    
    func testParseDetails_shouldFailIfShippingMethodsAreMissing() {
        var invalidDictionary = validDictionary
        invalidDictionary["shipping_methods"] = nil
        
        let cost = Cost.parseDetails(dictionary: invalidDictionary)
        XCTAssertNil(cost)
    }
    
    func testParseDetails_shouldPopulatePromoDiscountError() {
        var invalidDictionary = validDictionary
        invalidDictionary["promo_code"] = ["invalid_message": "Promo code not recognised"]
        
        let cost = Cost.parseDetails(dictionary: invalidDictionary)
        XCTAssertEqualOptional(cost?.promoCodeInvalidReason, "Promo code not recognised")
    }


}
