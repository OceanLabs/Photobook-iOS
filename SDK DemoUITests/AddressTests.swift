//
//  AddressTests.swift
//  SDK DemoUITests
//
//  Created by Konstadinos Karayannis on 09/05/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import XCTest

class AddressTests: PhotobookUITest {
    
    func testRequiredFields() {
        automation.goToBasket()
        automation.goToDeliveryDetailsFromBasket()
        automation.goToAddressFromDeliveryDetails()
        
        let line1TextField = automation.app.textFields["line1TextField"]
        let cityTextField = automation.app.textFields["cityTextField"]
        let zipOrPostalCodeTextField = automation.app.textFields["zipOrPostcodeTextField"]
        
        XCTAssertNotNil(line1TextField.value as? String)
        XCTAssertEqual(line1TextField.value as! String, "Required")
        
        XCTAssertNotNil(cityTextField.value as? String)
        XCTAssertEqual(cityTextField.value as! String, "Required")
        
        XCTAssertNotNil(zipOrPostalCodeTextField.value as? String)
        XCTAssertEqual(zipOrPostalCodeTextField.value as! String, "Required")
        
        automation.app.navigationBars["Address"].buttons["Save"].tap()
        XCTAssertTrue(line1TextField.isHittable, "Should not have navigated away since the required information is not entered")
        
        line1TextField.tap()
        line1TextField.typeText(automation.testAddressLine1)
        automation.app.navigationBars["Address"].buttons["Save"].tap()
        XCTAssertTrue(line1TextField.isHittable, "Should not have navigated away since the required information is not entered")
        
        cityTextField.tap()
        cityTextField.typeText(automation.testCity)
        automation.app.navigationBars["Address"].buttons["Save"].tap()
        XCTAssertTrue(line1TextField.isHittable, "Should not have navigated away since the required information is not entered")
        
        zipOrPostalCodeTextField.tap()
        zipOrPostalCodeTextField.typeText(automation.testPostalCode)
        automation.app.navigationBars["Address"].buttons["Save"].tap()
        XCTAssertFalse(line1TextField.exists, "We should have all the required information at this point so we should have navigated away")
    }

}
