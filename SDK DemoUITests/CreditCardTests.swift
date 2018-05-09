//
//  CreditCardTests.swift
//  SDK DemoUITests
//
//  Created by Konstadinos Karayannis on 09/05/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import XCTest

class CreditCardTests: PhotobookUITest {
    
    func testRequiredFields() {
        automation.goToBasket()
        automation.goToPaymentMethodFromBasket()
        automation.goToCreditCardFromPaymentMethod()
        
        let numberTextField = automation.app.textFields["numberTextField"]
        let expiryDateTextField = automation.app.textFields["expiryDateTextField"]
        let cvvTextField = automation.app.textFields["cvvTextField"]
        
        XCTAssertNotNil(numberTextField.value as? String)
        XCTAssertEqual(numberTextField.value as! String, "Required")
        
        XCTAssertNotNil(expiryDateTextField.value as? String)
        XCTAssertEqual(expiryDateTextField.value as! String, "Required")
        
        XCTAssertNotNil(cvvTextField.value as? String)
        XCTAssertEqual(cvvTextField.value as! String, "Required")
        
        automation.app.navigationBars["Card Details"].buttons["Save"].tap()
        XCTAssertTrue(numberTextField.isHittable, "Should not have navigated away since the required information is not entered")
        
        numberTextField.tap()
        numberTextField.typeText(automation.testCreditCardNumber)
        automation.app.navigationBars["Card Details"].buttons["Save"].tap()
        XCTAssertTrue(numberTextField.isHittable, "Should not have navigated away since the required information is not entered")
        
        expiryDateTextField.tap()
        automation.app.pickers.children(matching: .pickerWheel).element(boundBy: 0).swipeUp()
        automation.app.pickers.children(matching: .pickerWheel).element(boundBy: 1).swipeUp()
        automation.app.navigationBars["Card Details"].buttons["Save"].tap()
        XCTAssertTrue(numberTextField.isHittable, "Should not have navigated away since the required information is not entered")
        
        cvvTextField.tap()
        automation.app.secureTextFields["cvvTextField"].typeText(automation.testCreditCardCVV) // Changes to secure text field
        automation.app.navigationBars["Card Details"].buttons["Save"].tap()
        XCTAssertFalse(numberTextField.exists, "We should have all the required information at this point so we should have navigated away")
    }

}
