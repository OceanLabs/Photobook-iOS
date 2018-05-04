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
                                        "previewImageUrl":"https://image.kite.ly/render/?product_id=twill_tote_bag&variant=back2_melange_black&format=jpeg&debug=false&background=efefef"]
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testValidSummary() {
        let orderSummary = OrderSummary(validDictionary)
        XCTAssertNotNil(orderSummary)
    }
    
    func testValidPreviewImageUrl() {

        guard let validSummary = OrderSummary(validDictionary) else {
            XCTFail()
            return
        }
        
        XCTAssertNotNil(validSummary.previewImageUrl(withCoverImageUrl: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSxaHHyizN8O0OXTTQcZXbesl-6J-X0QWhZ1wcYiflygU4KiM2T8Q", size: CGSize(width: 300, height: 150)))
        XCTAssertNil(validSummary.previewImageUrl(withCoverImageUrl: "https://encrypted-tbn 0.gstatic.com/images?q=tbn:ANd9GcSxaHHyizN8O0OXTTQcZXbesl-6J-X0QWhZ1wcYiflygU4KiM2T8Q", size: CGSize(width: 300, height: 150)))
        
        
        let invalidUrlDictionary:[String:Any] = ["lineItems":[["name":"book", "price":["currencyCode":"GBP", "amount":30.0]],
                                                              ["name":"Glossy finish", "price":["currencyCode":"GBP", "amount":5.0]]],
                                                 "total":["currencyCode":"GBP", "amount":35.0],
                                                 "previewImageUrl":"somethingelse"]
        
        guard let invalidUrlSummary = OrderSummary(invalidUrlDictionary) else {
            XCTFail("Could not initialise OrderSummary object")
            return
        }
        
        //TODO: can't test this now as preview image not currently returned by server
        //XCTAssertNil(invalidUrlSummary.previewImageUrl(withCoverImageUrl: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSxaHHyizN8O0OXTTQcZXbesl-6J-X0QWhZ1wcYiflygU4KiM2T8Q", size: CGSize(width: 300, height: 150)))
    }
    
}
