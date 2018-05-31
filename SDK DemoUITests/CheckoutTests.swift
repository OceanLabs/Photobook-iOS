//
//  CheckoutTests.swift
//  SDK DemoUITests
//
//  Created by Konstadinos Karayannis on 31/05/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import XCTest

class CheckoutTests: PhotobookUITest {
    
    func testCheckout() {
        automation.goToBasket()
        automation.addNewCreditCardFromBasket()
        automation.fillDeliveryDetailsFromBasket()
        automation.app.buttons["payButton"].tap()
        
        let processingOrderStaticText = automation.app.tables/*@START_MENU_TOKEN@*/.staticTexts["Processing Order"]/*[[".cells.staticTexts[\"Processing Order\"]",".staticTexts[\"Processing Order\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
        wait(for: processingOrderStaticText)
        
        wait(2) // Wait for the notifications popup to appear
        
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        
        let allowBtn = springboard.buttons["Allow"]
        if allowBtn.exists {
            allowBtn.tap()
        }
    }

}
