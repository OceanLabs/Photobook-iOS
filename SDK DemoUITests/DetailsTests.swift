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
        
        let nameTextField = automation.app.cells["nameCell"].textFields["userInputTextField"]
        let lastNameTextField = automation.app.cells["lastNameCell"].textFields["userInputTextField"]
        let emailTextField = automation.app.cells["emailCell"].textFields["userInputTextField"]
        let phoneTextField = automation.app.cells["phoneCell"].textFields["userInputTextField"]
        
        XCTAssertNotNil(nameTextField.value as? String)
        XCTAssertEqual(nameTextField.value as! String, "Required")
        
        XCTAssertNotNil(lastNameTextField.value as? String)
        XCTAssertEqual(lastNameTextField.value as! String, "Required")
        
        XCTAssertNotNil(emailTextField.value as? String)
        XCTAssertEqual(emailTextField.value as! String, "Required")
        
        XCTAssertNotNil(phoneTextField.value as? String)
        XCTAssertEqual(phoneTextField.value as! String, "Required")
        
        let addressErrorMessageLabel = automation.app.staticTexts["addressErrorMessageLabel"]
        XCTAssertEqual(addressErrorMessageLabel.label, "")
        
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
    
    func testInvalidInput() {
        automation.goToBasket()
        automation.goToDeliveryDetailsFromBasket()
        
        let emailTextField = automation.app.cells["emailCell"].textFields["userInputTextField"]
        let phoneTextField = automation.app.cells["phoneCell"].textFields["userInputTextField"]
        let emailMessageLabel = automation.app.cells["emailCell"].staticTexts["userInputMessageLabel"]
        let phoneMessageLabel = automation.app.cells["phoneCell"].staticTexts["userInputMessageLabel"]
        
        // Email
        XCTAssertEqual(emailMessageLabel.label, "", "We should not be showing an error message at this time")
        emailTextField.tap()
        emailTextField.typeText("i.am.a.clown.email.com\n")
        XCTAssertEqual(emailMessageLabel.label, "Email is invalid.", "We should be showing an error message at this time")
        
        emailTextField.tap()
        emailTextField.typeText("this.is.a.valid.email@tada.com\n")
        XCTAssertEqual(emailMessageLabel.label, "", "The email is valid. We should not be showing an error message")
        
        // Phone
        XCTAssertEqual(phoneMessageLabel.label, "Required by the postal service in case there are any issues with the delivery", "We should not be showing an error message at this time")
        phoneTextField.tap()
        phoneTextField.typeText("1234\n")
        XCTAssertEqual(phoneMessageLabel.label, "Phone is invalid.", "We should be showing an error message at this time")
        
        phoneTextField.tap()
        phoneTextField.typeText("1234567890\n")
        XCTAssertEqual(phoneMessageLabel.label, "Required by the postal service in case there are any issues with the delivery", "The phone is valid. We should not be showing an error message")
    }

}
