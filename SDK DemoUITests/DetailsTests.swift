//
//  DetailsTests.swift
//  SDK DemoUITests
//
//  Created by Konstadinos Karayannis on 04/05/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import XCTest

class DetailsTests: PhotobookUITest {
    
    func testRequiredFields() {
        automation.goToBasket()
        automation.goToDeliveryDetailsFromBasket()
        
        let nameTextField = automation.app.textFields["nameTextField"]
        let lastNameTextField = automation.app.textFields["lastNameTextField"]
        let emailTextField = automation.app.textFields["emailTextField"]
        let phoneTextField = automation.app.textFields["phoneTextField"]
        
        XCTAssertNotNil(nameTextField.value)
        XCTAssertEqual(nameTextField.value as! String, "Required")
        
        XCTAssertNotNil(lastNameTextField.value)
        XCTAssertEqual(lastNameTextField.value as! String, "Required")
        
        XCTAssertNotNil(emailTextField.value)
        XCTAssertEqual(emailTextField.value as! String, "Required")
        
        XCTAssertNotNil(phoneTextField.value)
        XCTAssertEqual(phoneTextField.value as! String, "Required")
        
        let addressErrorMessageLabel = automation.app.staticTexts["addressErrorMessageLabel"]
        XCTAssertEqual(addressErrorMessageLabel.value as! String, "")
        
        automation.app.navigationBars["Delivery Details"].buttons["Save"].tap()
        XCTAssertTrue(nameTextField.isHittable, "Should not have navigated away since the required information is not entered")
        
        nameTextField.tap()
        nameTextField.typeText(automation.testName)
        automation.app.navigationBars["Delivery Details"].buttons["Save"].tap()
        XCTAssertTrue(nameTextField.isHittable, "Should not have navigated away since the required information is not entered")
        
        lastNameTextField.tap()
        lastNameTextField.typeText(automation.testLastName)
        automation.app.navigationBars["Delivery Details"].buttons["Save"].tap()
        XCTAssertTrue(nameTextField.isHittable, "Should not have navigated away since the required information is not entered")
        
        emailTextField.tap()
        emailTextField.typeText(automation.testEmail)
        automation.app.navigationBars["Delivery Details"].buttons["Save"].tap()
        XCTAssertTrue(nameTextField.isHittable, "Should not have navigated away since the required information is not entered")
        
        phoneTextField.tap()
        phoneTextField.typeText(automation.testPhone)
        automation.app.navigationBars["Delivery Details"].buttons["Save"].tap()
        XCTAssertTrue(nameTextField.isHittable, "Should not have navigated away since the required information is not entered")
        
        XCTAssertNotNil(addressErrorMessageLabel.value)
        XCTAssertEqual(addressErrorMessageLabel.label, "Required")
        
        automation.goToAddressFromDeliveryDetails()
        automation.fillAddressAndSave()
        
        automation.app.navigationBars["Delivery Details"].buttons["Save"].tap()
        
        XCTAssertFalse(nameTextField.exists, "We should have all the required information at this point so we should have navigated away")
    }

}
