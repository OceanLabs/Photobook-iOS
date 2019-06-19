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
        
        let shippingMethod = ShippingMethod(id: id, name: name, price: cost, maxDeliveryTime: maxDeliveryTime, minDeliveryTime: minDeliveryTime)
        
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
