//
//  CreditCardTests.swift
//  PhotobookTests
//
//  Created by Konstadinos Karayannis on 22/01/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import XCTest
@testable import Photobook

class CreditCardTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testCreditCardFormatterEmptyInput() {
        let input = ""
        let expected = ""
        let actual = input.creditCardFormatted()
        XCTAssert(actual == expected, "Credit card number formatter does not work properly. Expected: \(expected) but got: \(actual)")
    }
    
    func testCreditCardFormatter3CharacterInput() {
        let input = "123"
        let expected = "123"
        let actual = input.creditCardFormatted()
        XCTAssert(actual == expected, "Credit card number formatter does not work properly. Expected: \(expected) but got: \(actual)")
    }
    
    func testCreditCardFormatter4CharacterInput() {
        let input = "1234"
        let expected = "1234"
        let actual = input.creditCardFormatted()
        XCTAssert(actual == expected, "Credit card number formatter does not work properly. Expected: \(expected) but got: \(actual)")
    }
    
    func testCreditCardFormatter5CharacterInput() {
        let input = "12345"
        let expected = "1234 5"
        let actual = input.creditCardFormatted()
        XCTAssert(actual == expected, "Credit card number formatter does not work properly. Expected: \(expected) but got: \(actual)")
    }
    
    func testCreditCardFormatterAMEXInput() {
        let input = "378282246310005"
        let expected = "3782 822463 10005"
        let actual = input.creditCardFormatted()
        XCTAssert(actual == expected, "Credit card number formatter does not work properly. Expected: \(expected) but got: \(actual)")
        
        let type = input.cardType()
        XCTAssert(type == .amex, "Expected AMEX type but got \(type.debugDescription)")
    }
    
    func testCreditCardFormatterVisaInput() {
        let input = "4242424242424242"
        let expected = "4242 4242 4242 4242"
        let actual = input.creditCardFormatted()
        XCTAssert(actual == expected, "Credit card number formatter does not work properly. Expected: \(expected) but got: \(actual)")
        
        let type = input.cardType()
        XCTAssert(type == .visa, "Expected Visa type but got \(type.debugDescription)")
    }
}
