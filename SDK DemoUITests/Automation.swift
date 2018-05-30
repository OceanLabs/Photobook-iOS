//
//  Automation.swift
//  SDK DemoUITests
//
//  Created by Konstadinos Karayannis on 24/04/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import XCTest

class Automation {
    
    let testName = "Clown"
    let testLastName = "Clownberg"
    let testEmail = "clown@example.com"
    let testPhone = "1234567890"
    let testAddressLine1 = "Fiesta Blvd 2"
    let testCity = "Clown City"
    let testPostalCode = "11111"
    let testCreditCardNumber = "4242424242424242"
    let testCreditCardCVV = "111"
    
    let app: XCUIApplication
    let testCase: XCTestCase
    
    init(app: XCUIApplication, testCase: XCTestCase) {
        self.app = app
        self.testCase = testCase
    }

    func goToPhotobookReview() {
        app.buttons["Create Photobook with web photos"].tap()
        
        let checkoutButton = app.buttons["Checkout"]
        testCase.wait(for: checkoutButton)
    }
    
    func goToOrderSummary() {
        goToPhotobookReview()
        
        let checkoutButton = app.buttons["Checkout"]
        checkoutButton.tap()
        
        let continueButton = app.buttons["Continue"]
        testCase.wait(for: continueButton)
    }
    
    func goToBasket() {
        goToOrderSummary()
        
        let continueButton = app.buttons["Continue"]
        continueButton.tap()
        
        testCase.wait(for: app.buttons["payButton"])
    }
    
    func fillDeliveryDetailsFromBasket() {
        goToDeliveryDetailsFromBasket()
        fillDeliveryDetailsAndSave()
    }
    
    func goToDeliveryDetailsFromBasket() {
        app.buttons["deliveryDetailsView"].tap()
    }
    
    func fillDeliveryDetailsAndSave() {
        let tablesQuery = app.tables
        let nameTextField = tablesQuery.cells.containing(.staticText, identifier:"Name").textFields["userInputTextField"]
        nameTextField.tap()
        nameTextField.clearTextField()
        nameTextField.typeText(testName)
        
        let lastNameTextField = tablesQuery.cells.containing(.staticText, identifier:"Last Name").textFields["userInputTextField"]
        lastNameTextField.tap()
        lastNameTextField.clearTextField()
        lastNameTextField.typeText(testLastName)
        
        let emailTextField = tablesQuery.cells.containing(.staticText, identifier:"Email").textFields["userInputTextField"]
        emailTextField.tap()
        emailTextField.clearTextField()
        emailTextField.typeText(testEmail)
        
        let phoneTextField = tablesQuery.cells.containing(.staticText, identifier:"Phone").textFields["userInputTextField"]
        phoneTextField.tap()
        phoneTextField.clearTextField()
        phoneTextField.typeText(testPhone)
        
        goToAddressFromDeliveryDetails()
        
        fillAddressAndSave()
        
        app.navigationBars["Delivery Details"].buttons["Save"].tap()
    }
    
    func goToAddressFromDeliveryDetails() {
        app.tables/*@START_MENU_TOKEN@*/.buttons["Add delivery address"]/*[[".cells.buttons[\"Add delivery address\"]",".buttons[\"Add delivery address\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
    }
    
    func fillAddressAndSave() {
        let tablesQuery = app.tables
        let line1TextField = tablesQuery.cells.containing(.staticText, identifier:"Line1").textFields["line1TextField"]
        line1TextField.tap()
        line1TextField.clearTextField()
        line1TextField.typeText(testAddressLine1)
        
        
        let cityTextField = tablesQuery.cells.containing(.staticText, identifier:"City").textFields["cityTextField"]
        cityTextField.tap()
        cityTextField.clearTextField()
        cityTextField.typeText(testCity)
        
        var zipOrPostalTextField = tablesQuery.cells.containing(.staticText, identifier:"Zip Code").textFields["zipOrPostcodeTextField"]
        if !zipOrPostalTextField.exists {
            zipOrPostalTextField = tablesQuery.cells.containing(.staticText, identifier:"Postcode").textFields["zipOrPostcodeTextField"]
        }
        zipOrPostalTextField.tap()
        zipOrPostalTextField.clearTextField()
        zipOrPostalTextField.typeText(testPostalCode)
        
        app.navigationBars["Address"].buttons["Save"].tap()
    }
    
    func addNewCreditCardFromBasket() {
        goToPaymentMethodFromBasket()
        goToCreditCardFromPaymentMethod()
        fillCreditCardAndSave()
        app.navigationBars["Payment Methods"].buttons["Back"].tap()
    }
    
    func goToPaymentMethodFromBasket() {
        app.buttons["paymentMethodView"].tap()
    }
    
    func goToCreditCardFromPaymentMethod() {
        app.tables/*@START_MENU_TOKEN@*/.buttons["Add Payment Method"]/*[[".cells.buttons[\"Add Payment Method\"]",".buttons[\"Add Payment Method\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
    }
    
    func fillCreditCardAndSave() {
        let cardNumberTextField = app.tables.cells["numberCell"].textFields["userInputTextField"]
        cardNumberTextField.tap()
        cardNumberTextField.typeText(testCreditCardNumber)
        
        app.toolbars["Toolbar"].buttons["Next"].tap()
        
        app.pickers.children(matching: .pickerWheel).element(boundBy: 0).swipeUp()
        app.pickers.children(matching: .pickerWheel).element(boundBy: 1).swipeUp()
        
        app.toolbars["Toolbar"].buttons["Next"].tap()
        
        let cvvTextField = app.cells["cvvCell"].secureTextFields["userInputTextField"]
        cvvTextField.typeText(testCreditCardCVV)
        
        app.navigationBars["Card Details"].buttons["Save"].tap()
    }
    
}
