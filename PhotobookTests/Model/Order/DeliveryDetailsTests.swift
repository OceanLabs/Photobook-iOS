//
//  DeliveryDetailsTests.swift
//  PhotobookTests
//
//  Created by Jaime Landazuri on 30/05/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import XCTest
@testable import Photobook

class DeliveryDetailsTests: XCTestCase {
    
    func validDetails() -> DeliveryDetails {
        let deliveryDetails = DeliveryDetails()
        deliveryDetails.firstName = "George"
        deliveryDetails.lastName = "Clowney"
        
        let address = Address()
        address.line1 = "9 Fiesta Place"
        address.city = "London"
        address.zipOrPostcode = "CL0 WN4"
        
        deliveryDetails.address = address
        deliveryDetails.email = "g.clowney@clownmail.com"
        deliveryDetails.phone = "399945528234"
        return deliveryDetails
    }
    
    func testIsValid_shouldBeTrueWithAValidAddress() {
        let deliveryDetails = validDetails()
        XCTAssertTrue(deliveryDetails.isValid)
    }
    
    func testIsValid_shouldBeFalseIfFirstNameIsMissing() {
        let deliveryDetails = validDetails()
        deliveryDetails.firstName = nil
        XCTAssertFalse(deliveryDetails.isValid)
    }
    
    func testIsValid_shouldBeFalseIfFirstNameIsEmpty() {
        let deliveryDetails = validDetails()
        deliveryDetails.firstName = ""
        XCTAssertFalse(deliveryDetails.isValid)
    }

    func testIsValid_shouldBeFalseIfLastNameIsMissing() {
        let deliveryDetails = validDetails()
        deliveryDetails.lastName = nil
        XCTAssertFalse(deliveryDetails.isValid)
    }
    
    func testIsValid_shouldBeFalseIfLastNameIsEmpty() {
        let deliveryDetails = validDetails()
        deliveryDetails.lastName = ""
        XCTAssertFalse(deliveryDetails.isValid)
    }
    
    func testIsValid_shouldBeFalseIfAddressIsMissing() {
        let deliveryDetails = validDetails()
        deliveryDetails.address = nil
        XCTAssertFalse(deliveryDetails.isValid)
    }

    func testIsValid_shouldBeFalseIfEmailIsMissing() {
        let deliveryDetails = validDetails()
        deliveryDetails.email = nil
        XCTAssertFalse(deliveryDetails.isValid)
    }

    func testIsValid_shouldBeFalseIfEmailIsNotValid() {
        let deliveryDetails = validDetails()
        deliveryDetails.email = "notrealmail@bonkers"
        XCTAssertFalse(deliveryDetails.isValid)
    }
    
    func testIsValid_shouldBeFalseIfPhoneIsMissing() {
        let deliveryDetails = validDetails()
        deliveryDetails.phone = nil
        XCTAssertFalse(deliveryDetails.isValid)
    }
    
    func testIsValid_shouldBeFalseIfPhoneIsNotValid() {
        let deliveryDetails = validDetails()
        deliveryDetails.phone = "3434"
        XCTAssertFalse(deliveryDetails.isValid)
    }
    
    func testDetails_canBePersisted() {
        let deliveryDetails = validDetails()
        deliveryDetails.saveDetailsAsLatest()
        
        let retrievedDetails = DeliveryDetails.loadLatestDetails()
        XCTAssertEqualOptional(deliveryDetails, retrievedDetails)
    }
    
    func testFullName_shouldBeNilIfFirstNameAndLastNameAreMissing() {
        let deliveryDetails = validDetails()
        deliveryDetails.firstName = nil
        deliveryDetails.lastName = nil
        XCTAssertNil(deliveryDetails.fullName)
    }
    
    func testFullName_shouldReturnFullName() {
        let deliveryDetails = validDetails()
        XCTAssertEqualOptional(deliveryDetails.fullName, "George Clowney")
    }
    
    func testFullName_shouldReturnLastNameIfFirstNameIsMissing() {
        let deliveryDetails = validDetails()
        deliveryDetails.firstName = nil
        XCTAssertEqualOptional(deliveryDetails.fullName, "Clowney")
    }

    func testFullName_shouldReturnLastNameIfLastNameIsMissing() {
        let deliveryDetails = validDetails()
        deliveryDetails.lastName = nil
        XCTAssertEqualOptional(deliveryDetails.fullName, "George")
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: DeliveryDetails.savedDetailsKey)
    }
}
