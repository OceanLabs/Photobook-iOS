//
//  PaymentMethodTests.swift
//  SDK DemoUITests
//
//  Created by Konstadinos Karayannis on 09/05/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import XCTest

class PaymentMethodTests: PhotobookUITest {

    func testAddedCreditCard() {
        automation.goToBasket()
        automation.goToPaymentMethodFromBasket()
        
        let creditCardCell = automation.app.tables.cells["creditCardCell"]
        XCTAssertFalse(creditCardCell.exists, "We should not have a credit card cell at this time.")
        
        automation.goToCreditCardFromPaymentMethod()
        automation.fillCreditCardAndSave()
        
        
        let cardLabel = creditCardCell.staticTexts["paymentMethodNameLabel"].label
        
        XCTAssertEqual(cardLabel, "•••• •••• •••• " + automation.testCreditCardNumber.suffix(4))
    }
    
}
