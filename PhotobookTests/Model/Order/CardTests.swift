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
