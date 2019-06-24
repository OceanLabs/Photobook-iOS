//
//  Modified MIT License
//
//  Copyright (c) 2010-2018 Kite Tech Ltd. https://www.kite.ly
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The software MAY ONLY be used with the Kite Tech Ltd platform and MAY NOT be modified
//  to be used with any competitor platforms. This means the software MAY NOT be modified
//  to place orders with any competitors to Kite Tech Ltd, all orders MUST go through the
//  Kite Tech Ltd platform servers.
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import XCTest
@testable import Photobook

class CostTests: XCTestCase {
    
    
    let validDictionary: [String: Any] = [
        "total_shipping_costs": ["GBP": 7.06, "EUR": 8.039999999999999],
        "promo_code": [
            "discount": ["GBP": 2, "EUR": 2.5]
        ],
        "total_costs": ["GBP": 26.06, "EUR": 30.53],
        "shipping_discount": ["GBP": 0, "EUR": 0],
        "total_product_costs": ["GBP": 21, "EUR": 24.99],
        "shipments": [
            ["items": [
                ["job_id": "<null>",
                 "quantity": 1,
                 "shipping_cost": ["GBP": 7.06, "EUR": 8.039999999999999],
                 "template_id": "hdbook_127x127",
                 "product_costs": ["GBP": 21, "EUR": 24.99],
                 "description": "1 x Premium Square Photobook 12.7cm (Matte)",
                 "upsell_discount": ["GBP": 0, "EUR": 0]]
                ]]
        ]
    ]
    
    func testInit() {
        let hash = 233
        let totalShippingCost = Price(currencyCode: "GBP", value: 7.06)
        let promoDiscount = Price(currencyCode: "GBP", value: 0)
        let promoCodeInvalidReason = "reason"
        let total = Price(currencyCode: "GBP", value: 28.06)
        let lineItems = [LineItem(templateId: "hdbook_127x127", name: "item", price: Price(currencyCode: "GBP", value: 21), identifier: "")]
        
        let cost = Cost(hash: hash, lineItems: lineItems, totalShippingPrice: totalShippingCost, total: total, promoDiscount: promoDiscount, promoCodeInvalidReason: promoCodeInvalidReason)
        
        XCTAssertEqual(cost.orderHash, 233)
        XCTAssertEqualOptional(cost.lineItems.first?.templateId, "hdbook_127x127")
        XCTAssertEqualOptional(cost.lineItems.first?.name, "item")
        XCTAssertEqualOptional(cost.lineItems.first?.price, lineItems.first?.price)
        XCTAssertEqualOptional(cost.promoDiscount, promoDiscount)
        XCTAssertEqualOptional(cost.promoCodeInvalidReason, "reason")
    }
    
    func testParseDetails_shoudParseAValidDictionary() {
        let cost = Cost.parseDetails(dictionary: validDictionary)
        
        XCTAssertNotNil(cost)
        XCTAssertEqualOptional(cost?.lineItems.count, 1)
    }
    
    func testParseDetails_shouldHaveAReasonForAnInvalidCode() {
        var invalidCodeDictionary = validDictionary
        invalidCodeDictionary["promo_code"] = ["invalid_message": "The code you entered is invalid"]
        let cost = Cost.parseDetails(dictionary: invalidCodeDictionary)
        
        XCTAssertNotNil(cost)
        XCTAssertEqualOptional(cost?.promoCodeInvalidReason, "Invalid code")
    }
    
    func testParseDetails_shouldFailIfLineItemsAreMissing() {
        var invalidDictionary = validDictionary
        invalidDictionary["shipments"] = nil
        
        let cost = Cost.parseDetails(dictionary: invalidDictionary)
        XCTAssertNil(cost)
    }
    
    func testParseDetails_shouldFailIfTotalIsissing() {
        var invalidDictionary = validDictionary
        invalidDictionary["total_costs"] = nil
        
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
