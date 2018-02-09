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
    
    let validDictionary:[String:Any] = ["details":[["name":"book", "price":"£50.00"],
                                                   ["name":"Glossy finish", "price":"£10.00"]],
                                        "total":"£60.00",
                                        "imagePreviewUrl":"https://image.kite.ly/render/?product_id=twill_tote_bag&variant=back2_melange_black&format=jpeg&debug=false&background=efefef"]
    
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
        
        
        let invalidUrlDictionary:[String:Any] = ["details":[["name":"book", "price":"£50.00"],
                                                            ["name":"Glossy finish", "price":"£10.00"]],
                                                 "total":"£60.00",
                                                 "imagePreviewUrl":"somethingelse"]
        
        guard let invalidUrlSummary = OrderSummary(invalidUrlDictionary) else {
            XCTFail("Could not initialise OrderSummary object")
            return
        }
        
        XCTAssertNil(invalidUrlSummary.previewImageUrl(withCoverImageUrl: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSxaHHyizN8O0OXTTQcZXbesl-6J-X0QWhZ1wcYiflygU4KiM2T8Q", size: CGSize(width: 300, height: 150)))
    }
    
}
