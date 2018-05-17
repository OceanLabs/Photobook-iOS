//
//  BasketTests.swift
//  SDK DemoUITests
//
//  Created by Konstadinos Karayannis on 25/04/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import XCTest

class BasketTests: PhotobookUITest {
    
    func testQuantityChange() {
        automation.goToBasket()
        
        let quantityButton = automation.app.buttons["quantityButton"]
        let oldValue = quantityButton.value as? String
        XCTAssertNotNil(oldValue)
        XCTAssertEqual(oldValue!, "1")
        
        quantityButton.tap()
        
        let picker = automation.app.pickerWheels["1"]
        let pickerLocation = picker.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        pickerLocation.press(forDuration: 0, thenDragTo: picker.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.0)))
        
        automation.app.buttons["Done"].tap()
        
        let newValue = quantityButton.value as? String
        XCTAssertNotNil(newValue)
        XCTAssertGreaterThan(newValue!, oldValue!)
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
    
    func testAddressRequired() {
        automation.goToBasket()
        automation.addNewCreditCardFromBasket()
        
        let paymentMethodView = automation.app.buttons["paymentMethodView"]
        let paymentMethodViewValue = paymentMethodView.value as? String
        XCTAssertNotNil(paymentMethodViewValue)
        XCTAssertEqual(paymentMethodViewValue!, "Visa")
        
        let deliveryDetailsView = automation.app.buttons["deliveryDetailsView"]
        XCTAssertTrue(deliveryDetailsView.value as? String == nil || (deliveryDetailsView.value as! String).isEmpty, "We should be showing no details or warning at this point")
        
        let payButton = automation.app.buttons["payButton"]
        payButton.tap()
        
        XCTAssertTrue(payButton.isHittable, "Moved to another screen when we should have stayed on the basket screen")
        
        XCTAssertNotNil(deliveryDetailsView.value as? String)
        XCTAssertEqual(deliveryDetailsView.value as! String, "Required", "We didn't show the user that delivery details are required")
        
        automation.fillDeliveryDetailsFromBasket()
        
        XCTAssertNotNil(deliveryDetailsView.value as? String)
        XCTAssertTrue((deliveryDetailsView.value as! String).contains("\(automation.testAddressLine1), \(automation.testPostalCode), "), "We didn't show the preview of the delivery details")
    }
    
}
