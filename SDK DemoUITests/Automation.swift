//
//  Automation.swift
//  SDK DemoUITests
//
//  Created by Konstadinos Karayannis on 24/04/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import XCTest

class Automation {
    
    let app: XCUIApplication
    let testCase: XCTestCase
    
    init(app: XCUIApplication, testCase: XCTestCase) {
        self.app = app
        self.testCase = testCase
    }

    func goToPhotobookReview() {
        app.buttons["Create Photobook with web photos"].tap()
    }
    
    func goToOrderSummary() {
        goToPhotobookReview()
        
        let checkoutButton = app.buttons["Checkout"]
        testCase.wait(for: checkoutButton)
        checkoutButton.tap()
    }
    
    func goToBasket() {
        goToOrderSummary()
        
        let continueButton = app.buttons["Continue"]
        testCase.wait(for: continueButton)
        continueButton.tap()
    }
    
    func fillDeliveryDetailsFromBasket() {
        goToDeliveryDetailsFromBasket()
        fillDeliveryDetailsAndSave()
    }
    
    func goToDeliveryDetailsFromBasket() {
        let element = app.otherElements["Basket"].children(matching: .other).element(boundBy: 1)
        element.children(matching: .other).element(boundBy: 2).tap()
    }
    
    func fillDeliveryDetailsAndSave() {
        let tablesQuery = app.tables
        let nameTextField = tablesQuery.cells.containing(.staticText, identifier:"Name")/*@START_MENU_TOKEN@*/.textFields["TextField"]/*[[".textFields[\"Required\"]",".textFields[\"TextField\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
        nameTextField.tap()
        nameTextField.clearTextField()
        nameTextField.typeText("Clown")
        
        let lastNameTextField = tablesQuery.cells.containing(.staticText, identifier:"Last Name")/*@START_MENU_TOKEN@*/.textFields["TextField"]/*[[".textFields[\"Required\"]",".textFields[\"TextField\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
        lastNameTextField.tap()
        lastNameTextField.clearTextField()
        lastNameTextField.typeText("Clownberg")
        
        let emailTextField = tablesQuery.cells.containing(.staticText, identifier:"Email")/*@START_MENU_TOKEN@*/.textFields["TextField"]/*[[".textFields[\"Required\"]",".textFields[\"TextField\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
        emailTextField.tap()
        emailTextField.clearTextField()
        emailTextField.typeText("clown@example.com")
        
        let phoneTextField = tablesQuery.cells.containing(.staticText, identifier:"Phone")/*@START_MENU_TOKEN@*/.textFields["TextField"]/*[[".textFields[\"Required\"]",".textFields[\"TextField\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
        phoneTextField.tap()
        phoneTextField.clearTextField()
        phoneTextField.typeText("1234567890")
        
        goToAddressFromDeliveryDetails()
        
        fillAddressAndSave()
        
        app.navigationBars["Delivery Details"].buttons["Save"].tap()
    }
    
    func goToAddressFromDeliveryDetails() {
        app.tables/*@START_MENU_TOKEN@*/.buttons["Add delivery address"]/*[[".cells.buttons[\"Add delivery address\"]",".buttons[\"Add delivery address\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
    }
    
    func fillAddressAndSave() {
        let tablesQuery = app.tables
        let line1TextField = tablesQuery.cells.containing(.staticText, identifier:"Line1")/*@START_MENU_TOKEN@*/.textFields["TextField"]/*[[".textFields[\"Required\"]",".textFields[\"TextField\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
        line1TextField.tap()
        line1TextField.clearTextField()
        line1TextField.typeText("Fiesta Blvd 2")
        
        
        let cityTextField = tablesQuery.cells.containing(.staticText, identifier:"City")/*@START_MENU_TOKEN@*/.textFields["TextField"]/*[[".textFields[\"Required\"]",".textFields[\"TextField\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
        cityTextField.tap()
        cityTextField.clearTextField()
        cityTextField.typeText("Clown City")
        
        let zipTextField = tablesQuery.cells.containing(.staticText, identifier:"Zip Code")/*@START_MENU_TOKEN@*/.textFields["TextField"]/*[[".textFields[\"Required\"]",".textFields[\"TextField\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
        zipTextField.tap()
        zipTextField.clearTextField()
        zipTextField.typeText("11111")
        
        app.navigationBars["Address"].buttons["Save"].tap()
    }
    
    func addNewCreditCardFromBasket() {
        goToPaymentMethodFromBasket()
        goToCreditCardFromPaymentMethod()
        fillCreditCardAndSave()
        app.navigationBars["Payment Methods"].buttons["Back"].tap()
    }
    
    func goToPaymentMethodFromBasket() {
        XCUIApplication().otherElements["Basket"].children(matching: .other).element(boundBy: 1).children(matching: .other).element(boundBy: 4).tap()
    }
    
    func goToCreditCardFromPaymentMethod() {
        app.tables/*@START_MENU_TOKEN@*/.buttons["Add Payment Method"]/*[[".cells.buttons[\"Add Payment Method\"]",".buttons[\"Add Payment Method\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
    }
    
    func fillCreditCardAndSave() {
        let cardNumberTextField = app.tables.cells.containing(.staticText, identifier:"Card Number")/*@START_MENU_TOKEN@*/.textFields["TextField"]/*[[".textFields[\"Required\"]",".textFields[\"TextField\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
        cardNumberTextField.tap()
        cardNumberTextField.typeText("4242424242424242")
        
        app.toolbars["Toolbar"].buttons["Next"].tap()
        
        app.pickers.children(matching: .pickerWheel).element(boundBy: 0).swipeUp()
        app.pickers.children(matching: .pickerWheel).element(boundBy: 1).swipeUp()
        
        app.toolbars["Toolbar"].buttons["Next"].tap()
        
        let cvvTextField = app.tables/*@START_MENU_TOKEN@*/.secureTextFields["TextField"]/*[[".cells",".secureTextFields[\"Required\"]",".secureTextFields[\"TextField\"]"],[[[-1,2],[-1,1],[-1,0,1]],[[-1,2],[-1,1]]],[0]]@END_MENU_TOKEN@*/
        cvvTextField.typeText("111")
        
        app.navigationBars["Card Details"].buttons["Save"].tap()
    }
    
}
