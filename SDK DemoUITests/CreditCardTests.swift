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

class CreditCardTests: PhotobookUITest {
    
    func testRequiredFields() {
        automation.goToBasket()
        automation.goToPaymentMethodFromBasket()
        automation.goToCreditCardFromPaymentMethod()
        
        let numberTextField = automation.app.cells["numberCell"].textFields["userInputTextField"]
        let expiryDateTextField = automation.app.cells["expiryDateCell"].textFields["userInputTextField"]
        let cvvTextField = automation.app.cells["cvvCell"].textFields["userInputTextField"]
        
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
        automation.app.cells["cvvCell"].secureTextFields["userInputTextField"].typeText(automation.testCreditCardCVV) // Changes to secure text field
        automation.app.navigationBars["Card Details"].buttons["Save"].tap()
        XCTAssertFalse(numberTextField.exists, "We should have all the required information at this point so we should have navigated away")
    }
    
    func testInvalidCardDetails() {
        automation.goToBasket()
        automation.goToPaymentMethodFromBasket()
        automation.goToCreditCardFromPaymentMethod()
        
        let numberMessageLabel = automation.app.cells["numberCell"].staticTexts["messageLabel"]
        XCTAssertEqual(numberMessageLabel.label, "", "We should not be showing an error message at this time")
        
        let expiryDateMessageLabel = automation.app.cells["expiryDateCell"].staticTexts["messageLabel"]
        XCTAssertEqual(expiryDateMessageLabel.label, "", "We should not be showing an error message at this time")
        
        let cvvMessageLabel = automation.app.cells["cvvCell"].staticTexts["messageLabel"]
        XCTAssertEqual(cvvMessageLabel.label, "", "We should not be showing an error message at this time")
        
        let numberTextField = automation.app.cells["numberCell"].textFields["userInputTextField"]
        numberTextField.tap()
        numberTextField.typeText("1111111111111111")
        
        let cvvTextField = automation.app.cells["cvvCell"].textFields["userInputTextField"]
        cvvTextField.tap()
        automation.app.cells["cvvCell"].secureTextFields["userInputTextField"].typeText("1") // Changes to secure text field
        
        automation.app.navigationBars["Card Details"].buttons["Save"].tap()
        XCTAssertEqual(numberMessageLabel.label, "This doesn't seem to be a valid card number.", "We should be showing an error message now")
        XCTAssertEqual(cvvMessageLabel.label, "The CVV is invalid. It should contain 3 to 4 digits.", "We should be showing an error message now")
        
        // Tapping on the fields should make the message go away
        numberTextField.tap()
        
        XCTAssertEqual(numberMessageLabel.label, "", "We should not be showing an error message any more")
        automation.app.cells["cvvCell"].secureTextFields["userInputTextField"].tap()
        XCTAssertEqual(cvvMessageLabel.label, "", "We should not be showing an error message any more")
        
    }

}
