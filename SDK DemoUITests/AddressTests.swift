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

class AddressTests: PhotobookUITest {
    
    func testRequiredFields() {
        automation.goToBasket()
        automation.goToDeliveryDetailsFromBasket()
        automation.goToAddressFromDeliveryDetails()
        
        let line1TextField = automation.app.textFields["line1TextField"]
        let cityTextField = automation.app.textFields["cityTextField"]
        let zipOrPostalCodeTextField = automation.app.textFields["zipOrPostcodeTextField"]
        let stateOrCountyTextField = automation.app.textFields["stateOrCountyTextField"]
        
        XCTAssertNotNil(line1TextField.value as? String)
        XCTAssertEqual(line1TextField.value as! String, "Required")
        
        XCTAssertNotNil(cityTextField.value as? String)
        XCTAssertEqual(cityTextField.value as! String, "Required")
        
        XCTAssertNotNil(zipOrPostalCodeTextField.value as? String)
        XCTAssertEqual(zipOrPostalCodeTextField.value as! String, "Required")
        
        automation.app.navigationBars["Address"].buttons["Save"].tap()
        XCTAssertTrue(line1TextField.isHittable, "Should not have navigated away since the required information is not entered")
        
        line1TextField.tap()
        line1TextField.typeText(automation.testAddressLine1)
        automation.app.navigationBars["Address"].buttons["Save"].tap()
        XCTAssertTrue(line1TextField.isHittable, "Should not have navigated away since the required information is not entered")
        
        cityTextField.tap()
        cityTextField.typeText(automation.testCity)
        automation.app.navigationBars["Address"].buttons["Save"].tap()
        XCTAssertTrue(line1TextField.isHittable, "Should not have navigated away since the required information is not entered")
        
        zipOrPostalCodeTextField.tap()
        zipOrPostalCodeTextField.typeText(automation.testPostalCode)
        automation.app.navigationBars["Address"].buttons["Save"].tap()
        XCTAssertTrue(line1TextField.isHittable, "Should not have navigated away since the required information is not entered")
        
        stateOrCountyTextField.tap()
        stateOrCountyTextField.typeText(automation.testCounty)
        automation.app.navigationBars["Address"].buttons["Save"].tap()
        XCTAssertFalse(line1TextField.exists, "We should have all the required information at this point so we should have navigated away")
    }

}
