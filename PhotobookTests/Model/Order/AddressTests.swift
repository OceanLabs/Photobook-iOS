//
//  AddressTests.swift
//  PhotobookTests
//
//  Created by Jaime Landazuri on 22/05/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import XCTest
@testable import Photobook

class AddressTests: XCTestCase {
    
    let validAddress: Address = {
        let address = Address()
        address.line1 = "Flat 29, 9 Clown Fiesta"
        address.line2 = "Old Street"
        address.city = "London"
        address.stateOrCounty = "Greater London"
        address.zipOrPostcode = "EC1 Y2A"
        address.country = Country(name: "United Kingdom", codeAlpha2: "UK", codeAlpha3: "GBA", currencyCode: "GBP")
        return address
    }()
    
    func testValid_shouldBeTrueWithCorrectData() {
        XCTAssertTrue(validAddress.isValid)
    }
    
    func testIsValid_shouldBeFalseIfLine1IsMissing() {
        let invalidAddress = validAddress.copy() as! Address
        invalidAddress.line1 = nil
        XCTAssertFalse(invalidAddress.isValid)
    }

    func testIsValid_shouldBeFalseIfTheCityIsMissing() {
        let invalidAddress = validAddress.copy() as! Address
        invalidAddress.city = nil
        XCTAssertFalse(invalidAddress.isValid)
    }
    
    func testIsValid_shouldBeFalseIfThePostCodeIsMissing() {
        let invalidAddress = validAddress.copy() as! Address
        invalidAddress.zipOrPostcode = nil
        XCTAssertFalse(invalidAddress.isValid)
    }

    func testDescriptionWithoutLine1_shouldReturnTheRightAddress() {
        let addressDescription = validAddress.descriptionWithoutLine1()
        XCTAssertEqual(addressDescription, "Old Street, London, Greater London, EC1 Y2A, United Kingdom")
    }
    
    func testSavedAddresses_shouldBeEmpty() {
        XCTAssertTrue(Address.savedAddresses.count == 0)
    }

    func testAddToSaveAddresses_shouldSaveTheAddress() {
        validAddress.addToSavedAddresses()
        XCTAssertTrue(Address.savedAddresses.contains(validAddress))
    }

    func testAddToSaveAddresses_shouldNotSaveTheAddressIfAlreadySaved() {
        validAddress.addToSavedAddresses()
        validAddress.addToSavedAddresses()
        XCTAssertTrue(Address.savedAddresses.count == 1)
    }

    func testRemoveFromSavedAddresses_shouldRemoveTheAddress() {
        validAddress.addToSavedAddresses()
        validAddress.removeFromSavedAddresses()
        XCTAssertFalse(Address.savedAddresses.contains(validAddress))
    }
    
    override func tearDown() {
        Address.savedAddresses = [Address]()
    }
}
