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

class OrderSummaryTests: XCTestCase {
    
    let validDictionary:[String:Any] = ["lineItems":[["name":"book", "price":["currencyCode":"GBP", "amount":30.0]],
                                                     ["name":"Glossy finish", "price":["currencyCode":"GBP", "amount":5.0]]],
                                        "total":["currencyCode":"GBP", "amount":35.0],
                                        "previewImageUrl":"https://image.kite.ly/render/?product_id=twill_tote_bag&variant=back2_melange_black&format=jpeg"]
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testParse_shouldSucceedWithValidSummary() {
        let orderSummary = OrderSummary.parse(validDictionary)
        XCTAssertNotNil(orderSummary)
    }
    
    func testParse_shouldFailWithMissingLineItems() {
        let invalidDictionary:[String:Any] = ["total":["currencyCode":"GBP", "amount":35.0],
                             "previewImageUrl":"https://image.kite.ly/render/?product_id=twill_tote_bag&variant=back2_melange_black&format=jpeg"]
        let orderSummary = OrderSummary.parse(invalidDictionary)
        XCTAssertNil(orderSummary)
    }
    
    func testParse_shouldFailWithInvalidLineItems() {
        let invalidDictionary:[String:Any] = ["lineItems":[["name":"book", "price":["currencyCode":"GBP"]],
                                                           ["name":"Glossy finish", "price":["currencyCode":"GBP", "amount":5.0]]],
                                              "total":["currencyCode":"GBP", "amount":35.0],
                                              "previewImageUrl":"https://image.kite.ly/render/?product_id=twill_tote_bag&variant=back2_melange_black&format=jpeg"]
        let orderSummary = OrderSummary.parse(invalidDictionary)
        XCTAssertNil(orderSummary)
    }
    
    func testParse_shouldFailWithMissingTotal() {
        let  invalidDictionary:[String:Any] = ["lineItems":[["name":"book", "price":["currencyCode":"GBP", "amount":30.0]],
                                          ["name":"Glossy finish", "price":["currencyCode":"GBP", "amount":5.0]]],
                             "previewImageUrl":"https://image.kite.ly/render/?product_id=twill_tote_bag&variant=back2_melange_black&format=jpeg"]
        let orderSummary = OrderSummary.parse(invalidDictionary)
        XCTAssertNil(orderSummary)
    }
    
    func testParse_shouldFailWithInvalidTotal() {
        let invalidDictionary:[String:Any] = ["lineItems":[["name":"book", "price":["currencyCode":"GBP", "amount":30.0]],
                                                              ["name":"Glossy finish", "price":["currencyCode":"GBP", "amount":5.0]]],
                                                 "total":["amount":35.0],
                                                 "previewImageUrl":"https://image.kite.ly/render/?product_id=twill_tote_bag&variant=back2_melange_black&format=jpeg"]
        let orderSummary = OrderSummary.parse(invalidDictionary)
        XCTAssertNil(orderSummary)
    }
}
