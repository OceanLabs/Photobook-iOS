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
    
}
