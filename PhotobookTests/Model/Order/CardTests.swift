//
//  CardTests.swift
//  PhotobookTests
//
//  Created by Jaime Landazuri on 14/05/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import XCTest
@testable import Photobook

class CardTests: XCTestCase {
    
    func testInitialisation() {
        let number = "1111 2222 3333 4444"
        let cvv2 = "333"
        let month = 1
        let year = 2020
        
        let card = Card(number: number, expireMonth: month, expireYear: year, cvv2: cvv2)
        
        XCTAssertEqual(card.number, number)
        XCTAssertEqual(card.cvv2, cvv2)
        XCTAssertEqual(card.expireMonth, month)
        XCTAssertEqual(card.expireYear, year)
    }
    
    func testMaskedNumber_masksAllButTheLastGroupOfDigitsForVisa() {
        let card = Card(number: "4111 1111 1111 1111", expireMonth: 1, expireYear: 2020, cvv2: "333")
        XCTAssertEqual(card.numberMasked, "•••• •••• •••• 1111")
    }
    
    func testMaskedNumber_masksAllButTheLastGroupOfDigitsForMasterCard() {
        let card = Card(number: "5500 0000 0000 0004", expireMonth: 1, expireYear: 2020, cvv2: "333")
        XCTAssertEqual(card.numberMasked, "•••• •••• •••• 0004")
    }
    
    func testMaskedNumber_masksAllButTheLastGroupOfDigitsForAmex() {
        let card = Card(number: "3400 000000 00009", expireMonth: 1, expireYear: 2020, cvv2: "333")
        XCTAssertEqual(card.numberMasked, "•••• •••••• 00009")
    }
    
    func testMaskedNumber_maskAllButTheLastGroupOfDigitsForAnyOtherCard() {
        // Diner's Club
        let card1 = Card(number: "3000 0000 0000 04", expireMonth: 1, expireYear: 2020, cvv2: "333")
        XCTAssertEqual(card1.numberMasked, "•••• •••• •••• 04")
        
        // Discover
        let card2 = Card(number: "6011 0000 0000 0004", expireMonth: 1, expireYear: 2020, cvv2: "333")
        XCTAssertEqual(card2.numberMasked, "•••• •••• •••• 0004")
    }
    
    func testMasketNumber_maskLast4DigitsWithNoGroups() {
        let card = Card(number: "4111111111111111", expireMonth: 1, expireYear: 2020, cvv2: "333")
        XCTAssertEqual(card.numberMasked, "•••• •••• •••• 1111")
    }

    func testMasketNumber_maskLast4DigitsWithNoGroupsForAmex() {
        let card = Card(number: "340000000000009", expireMonth: 1, expireYear: 2020, cvv2: "333")
        XCTAssertEqual(card.numberMasked, "•••• •••••• 00009")
    }

    func testCardIcon_returnsVisaLogo() {
        let icon = UIImage(namedInPhotobookBundle: "visa-logo")!
        let card = Card(number: "4111 1111 1111 1111", expireMonth: 1, expireYear: 2020, cvv2: "333")
        XCTAssertEqual(card.cardIcon, icon)
    }

    func testCardIcon_returnsMasterCardLogo() {
        let icon = UIImage(namedInPhotobookBundle: "mastercard-logo")!
        let card = Card(number: "5500 0000 0000 0004", expireMonth: 1, expireYear: 2020, cvv2: "333")
        XCTAssertEqual(card.cardIcon, icon)
    }

    func testCardIcon_returnsAmexLogo() {
        let icon = UIImage(namedInPhotobookBundle: "amex-logo")!
        let card = Card(number: "3400 000000 00009", expireMonth: 1, expireYear: 2020, cvv2: "333")
        XCTAssertEqual(card.cardIcon, icon)
    }

    func testCardIcon_returnsGenericCardLogo() {
        let icon = UIImage(namedInPhotobookBundle: "generic-card")!
        
        let card1 = Card(number: "3000 0000 0000 04", expireMonth: 1, expireYear: 2020, cvv2: "333")
        XCTAssertEqual(card1.cardIcon, icon)
        
        // Discover
        let card2 = Card(number: "6011 0000 0000 0004", expireMonth: 1, expireYear: 2020, cvv2: "333")
        XCTAssertEqual(card2.cardIcon, icon)
        
        // Rubbish
        let card3 = Card(number: "1100 00 0000 00", expireMonth: 1, expireYear: 2020, cvv2: "333")
        XCTAssertEqual(card3.cardIcon, icon)
    }
}
