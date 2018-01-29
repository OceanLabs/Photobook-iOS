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
        
        let archivedCountry = NSKeyedArchiver.archivedData(withRootObject: country)
        let unarchivedCountry = NSKeyedUnarchiver.unarchiveObject(with: archivedCountry) as! Country
        
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
