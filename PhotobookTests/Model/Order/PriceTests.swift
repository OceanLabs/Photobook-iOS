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
        let price = Price(currencyCode: currencyCode, value: value, formattingLocale: Locale(identifier: "en_US"))
        
        XCTAssertNotNil(price)
        XCTAssertEqualOptional(price.currencyCode, currencyCode)
        XCTAssertEqualOptional(price.value, value)
        XCTAssertEqualOptional(price.formatted, "£12.20")
    }

    func testParseDictionary_withValidDictionary() {
        let price = Price.parse(validDictionary, prioritizedCurrencyCodes: ["GBP"], formattingLocale: Locale(identifier: "en_US"))
        
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
        let price = Price.parse(validDictionaries, prioritizedCurrencyCodes: ["GBP"], formattingLocale: Locale(identifier: "en_US"))
        
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
