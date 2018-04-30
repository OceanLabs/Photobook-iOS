//
//  BasketTests.swift
//  SDK DemoUITests
//
//  Created by Konstadinos Karayannis on 25/04/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import XCTest

extension SDK_DemoUITests {
    
    func testQualityChange() {
        automation.goToBasket()
        
        automation.app.buttons["quantityButton"].tap()
        automation.app.pickerWheels["1"].swipeUp()
        automation.app.buttons["Done"].tap()
    }
    
    func testInvalidPromoCode() {
        automation.goToBasket()
        
        let promoCodeTextField = automation.app.textFields["promoCodeTextField"]
        promoCodeTextField.tap()
        
        let invalidPromoCode = "This is definitely a valid promo code"
        promoCodeTextField.typeText(invalidPromoCode + "\n")
        
        let predicate = NSPredicate(format: "value != \"\(invalidPromoCode)\"")
        expectation(for: predicate, evaluatedWith: promoCodeTextField, handler: nil)
        waitForExpectations(timeout: 60, handler: nil)
        
        let newTextFieldValue = promoCodeTextField.value as? String
        XCTAssertNotNil(newTextFieldValue)
        XCTAssert(newTextFieldValue!.contains("Invalid code"), "Invalid code messsage not shown")
    }
    
    
    
}
