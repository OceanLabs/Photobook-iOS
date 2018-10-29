//
//  CountryTests.swift
//  PhotobookTests
//
//  Created by Konstadinos Karayannis on 22/01/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
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
    
    func testCountrySearchByCode_shouldReturnCountry() {
        XCTAssertEqualOptional(Country.countryFor(code: "GR")?.name, "Greece", "Country search did not return the correct result")
    }
    
    func testCountrySearchByName_shouldReturnCountry() {
        XCTAssertEqualOptional(Country.countryFor(name: "Greece")?.codeAlpha3, "GRC", "Country search did not return the correct result")
    }
    
    func testCountrySearchByCode_shouldReturnNil() {
        XCTAssertNil(Country.countryFor(code: "CLND"), "Should be nil for a country that is not in the list")
    }

    func testCountrySearchByName_shouldReturnNil() {
        XCTAssertNil(Country.countryFor(name: "Clownland"), "Should be nil for a country that is not in the list")
    }
    
    func testCopy() {
        let country = Country(name: "Westeros", codeAlpha2: "RR", codeAlpha3: "GOT", currencyCode: "Silver")
        let myCopy = country.copy() as! Country
        
        XCTAssertEqual(country.name, myCopy.name)
        XCTAssertEqual(country.codeAlpha2, myCopy.codeAlpha2)
        XCTAssertEqual(country.codeAlpha3, myCopy.codeAlpha3)
        XCTAssertEqual(country.currencyCode, myCopy.currencyCode)
    }
}
