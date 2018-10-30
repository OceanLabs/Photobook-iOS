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

class CountryTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testCountryArchiveUnarchive() {
        let country = Country(name: "Westeros", codeAlpha2: "RR", codeAlpha3: "GOT", currencyCode: "Silver")
        
        guard let archivedCountry = try? PropertyListEncoder().encode(country) else { XCTFail("Failed to encode country"); return }
        guard let unarchivedCountry = try? PropertyListDecoder().decode(Country.self, from: archivedCountry) else { XCTFail("Failed to decode country"); return }
        
        XCTAssert(country.name == unarchivedCountry.name, "Unarchived country did not have the correct name")
        XCTAssert(country.codeAlpha2 == unarchivedCountry.codeAlpha2, "Unarchived country did not have the correct code2")
        XCTAssert(country.codeAlpha3 == unarchivedCountry.codeAlpha3, "Unarchived country did not have the correct code3")
        XCTAssert(country.currencyCode == unarchivedCountry.currencyCode, "Unarchived country did not have the correct currency")
    }
    
    func testCountrySearchByCodeAlpha2() {
        XCTAssert(Country.countryFor(code: "GR")?.name == "Greece", "Country search did not return the correct result")
    }
    
    func testCountrySearchByCodeAlpha3() {
        XCTAssert(Country.countryFor(name: "Greece")?.codeAlpha3 == "GRC", "Country search did not return the correct result")
    }
    
}
