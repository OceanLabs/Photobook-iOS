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

class BasketTests: PhotobookUITest {
    
    func testQuantityChange() {
        automation.goToBasket()
        
        let quantityButton = automation.app.buttons["quantityButton"].firstMatch
        let oldValue = quantityButton.value as? String
        XCTAssertNotNil(oldValue)
        XCTAssertEqual(oldValue!, "1")
        
        quantityButton.tap()
        
        let picker = automation.app.pickerWheels["1"]
        let pickerLocation = picker.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        pickerLocation.press(forDuration: 0, thenDragTo: picker.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.0)))
        
        automation.app.buttons["Done"].tap()
        
        wait(for: quantityButton)
        
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
        XCTAssertEqual(paymentMethodViewValue!, "Visa 4242")
        
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
