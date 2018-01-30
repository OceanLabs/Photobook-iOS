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
        
        let type = input.creditCardType()
        XCTAssert(type == .amex, "Expected AMEX type but got \(type)")
    }
    
    func testCreditCardFormatterVisaInput() {
        let input = "4242424242424242"
        let expected = "4242 4242 4242 4242"
        let actual = input.creditCardFormatted()
        XCTAssert(actual == expected, "Credit card number formatter does not work properly. Expected: \(expected) but got: \(actual)")
        
        let type = input.creditCardType()
        XCTAssert(type == .visa, "Expected Visa type but got \(type)")
    }
    
    func testCardGetters() {
        let cardNumber = "4242424242424242"
        let card = Card(number: cardNumber, expireMonth: 12, expireYear: 50, cvv2: "111")
        
        XCTAssert(card.number == cardNumber, "Card did not return correct credit card number. Expected: \(cardNumber) but got: \(card.number)")
        XCTAssert(card.numberMasked == "24242", "Card did not return correct masked credit card number. Expected 24242 but got: \(card.numberMasked)")
        XCTAssert(card.expireYear == 50, "Card did not return correct credit card expire year. Expected: 50 but got: \(card.expireYear)")
        XCTAssert(card.expireMonth == 12, "Card did not return correct credit card expire year. Expected: 12 but got: \(card.expireMonth)")
        XCTAssert(card.cvv2 == "111", "Card did not return correct credit card cvv2. Expected: 111 but got: \(card.cvv2)")
        XCTAssert(!card.isAmex, "Card reports that it isAmex but it is not")
        
        let amexCard = Card(number: "378282246310005", expireMonth: 12, expireYear: 50, cvv2: "111")
        XCTAssert(amexCard.isAmex, "Card did not report that it isAmex when it is")
    }
    
}
