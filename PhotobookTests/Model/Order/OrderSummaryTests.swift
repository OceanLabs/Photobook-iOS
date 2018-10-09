//
//  OrderSummaryTests.swift
//  PhotobookTests
//
//  Created by Julian Gruber on 08/02/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
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
