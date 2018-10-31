//
//  Modified MIT License
//
//  Copyright (c) 2010-2018 Kite Tech Ltd. https://www.kite.ly
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The software MAY ONLY be used with the Kite Tech Ltd platform and MAY NOT be modified
//  to be used with any competitor platforms. This means the software MAY NOT be modified
//  to place orders with any competitors to Kite Tech Ltd, all orders MUST go through the
//  Kite Tech Ltd platform servers.
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
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
    let testCounty = "Clownborough"
    let testCreditCardNumber = "4242424242424242"
    let testCreditCardCVV = "111"
    
    let app: XCUIApplication
    let testCase: XCTestCase
    
    init(app: XCUIApplication, testCase: XCTestCase) {
        self.app = app
        self.testCase = testCase
    }

    func goToPhotobookReview() {
        app.buttons["Clear processing order"].tap()
        app.buttons["Create Photobook with web photos"].tap()
        
        let checkoutButton = app.buttons["Checkout"]
        testCase.wait(for: checkoutButton)
    }
    
    func goToOrderSummary() {
        goToPhotobookReview()
        
        let checkoutButton = app.buttons["Checkout"]
        checkoutButton.tap()
        
        let continueButton = app.buttons["ctaButton"]
        testCase.wait(for: continueButton)
    }
    
    func goToBasket() {
        goToOrderSummary()
        
        let continueButton = app.buttons["ctaButton"]
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
        
        var stateOrCountyTextField = tablesQuery.cells.containing(.staticText, identifier:"State").textFields["stateOrCountyTextField"]
        if !stateOrCountyTextField.exists {
            stateOrCountyTextField = tablesQuery.cells.containing(.staticText, identifier:"County").textFields["stateOrCountyTextField"]
        }
        stateOrCountyTextField.tap()
        stateOrCountyTextField.clearTextField()
        stateOrCountyTextField.typeText(testCounty)
        
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
