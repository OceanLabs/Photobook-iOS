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
