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
        "total_shipping_cost": ["GBP": 7.06, "EUR": 8.039999999999999],
        "promo_code": [
            "invalid_message": "<null>",
            "discount": ["GBP": 2, "EUR": 2.5]
        ],
        "total": ["GBP": 26.06, "EUR": 30.53],
        "shipping_discount": ["GBP": 0, "EUR": 0],
        "total_product_cost": ["GBP": 21, "EUR": 24.99],
        "line_items": [
            ["job_id": "<null>",
             "quantity": 1,
             "shipping_cost": ["GBP": 7.06, "EUR": 8.039999999999999],
             "template_id": "hdbook_127x127",
             "product_cost": ["GBP": 21, "EUR": 24.99],
             "description": "1 x Premium Square Photobook 12.7cm (Matte)",
             "upsell_discount": ["GBP": 0, "EUR": 0]]
        ]
    ]
    
    func testInit() {
        let hash = 233
        let totalShippingCost = Price(currencyCode: "GBP", value: 7.06)
        let promoDiscount = Price(currencyCode: "GBP", value: 0)
        let promoCodeInvalidReason = "reason"
        let total = Price(currencyCode: "GBP", value: 28.06)
        let lineItems = [LineItem(id: "hdbook_127x127", name: "item", cost: Price(currencyCode: "GBP", value: 21)!)]
        
        let cost = Cost(hash: hash, lineItems: lineItems, totalShippingCost: totalShippingCost!, total: total!, promoDiscount: promoDiscount, promoCodeInvalidReason: promoCodeInvalidReason)
        
        XCTAssertEqual(cost.orderHash, 233)
        XCTAssertEqualOptional(cost.lineItems?.first?.id, "hdbook_127x127")
        XCTAssertEqualOptional(cost.lineItems?.first?.name, "item")
        XCTAssertEqualOptional(cost.lineItems?.first?.cost, lineItems.first?.cost)
        XCTAssertEqualOptional(cost.promoDiscount, promoDiscount)
        XCTAssertEqualOptional(cost.promoCodeInvalidReason, "reason")
    }

    func testParseDetails_shoudParseAValidDictionary() {
        let cost = Cost.parseDetails(dictionary: validDictionary)
        
        XCTAssertNotNil(cost)
        XCTAssertEqualOptional(cost?.lineItems?.count, 1)
    }
    
    func testParseDetails_shouldFailIfLineItemsAreMissing() {
        var invalidDictionary = validDictionary
        invalidDictionary["line_items"] = nil
        
        let cost = Cost.parseDetails(dictionary: invalidDictionary)
        XCTAssertNil(cost)
    }
    
    func testParseDetails_shouldFailIfTotalIsissing() {
        var invalidDictionary = validDictionary
        invalidDictionary["total"] = nil
        
        let cost = Cost.parseDetails(dictionary: invalidDictionary)
        XCTAssertNil(cost)
    }
    
    func testParseDetails_shouldPopulatePromoDiscountError() {
        var invalidDictionary = validDictionary
        invalidDictionary["promo_code"] = ["invalid_message": "Promo code not recognised"]
        
        let cost = Cost.parseDetails(dictionary: invalidDictionary)
        XCTAssertNotNil(cost?.promoCodeInvalidReason)
    }


}
