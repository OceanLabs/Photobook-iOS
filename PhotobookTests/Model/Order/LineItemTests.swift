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

class LineItemTests: XCTestCase {
    
    var validDictionary: [String: Any] = [
        "template_id": "circus_clown1",
        "description": "Clown Costume",
        "product_cost": ["GBP": 21, "EUR": 24.99],
        "job_id": "cL0wN-t4d4"
    ]
    
    func testInit() {
        let id = "item_no2"
        let name = "Item number 2"
        let price = Price(currencyCode: "GBP", value: 21)
        
        let lineItem = LineItem(templateId: id, name: name, price: price!, identifier: "")
        
        XCTAssertEqual(lineItem.templateId, id)
        XCTAssertEqual(lineItem.name, name)
        XCTAssertEqual(lineItem.price, price)
    }
    
    func testParseDetails_shouldParseAValidDictionary() {
        let locale = Locale(identifier: "en_US")
        let lineItem = LineItem.parseDetails(dictionary: validDictionary, prioritizedCurrencyCodes: ["GBP"], formattingLocale: locale)
        
        let expectedCost = Price(currencyCode: "GBP", value: 21, formattingLocale: locale)
        
        XCTAssertEqualOptional(lineItem?.templateId, "circus_clown1")
        XCTAssertEqualOptional(lineItem?.name, "Clown Costume")
        XCTAssertEqualOptional(lineItem?.price, expectedCost)
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
