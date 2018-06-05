//
//  PaymentAuthorizationManagerTests.swift
//  PhotobookTests
//
//  Created by Jaime Landazuri on 04/06/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import XCTest
import PassKit
@testable import Photobook

class PaymentAuthorizationManagerTests: XCTestCase {
    
    var delegate: TestPaymentAuthorizationManagerDelegate!
    var paymentAuthorizationManager: PaymentAuthorizationManager!
    
    func fakeOrder() -> TestOrder {
        let order = TestOrder()
        order.shippingMethod = 1
        
        let deliveryDetails = DeliveryDetails()
        deliveryDetails.firstName = "George"
        deliveryDetails.lastName = "Clowney"
        
        let address = Address()
        address.line1 = "9 Fiesta Place"
        address.city = "London"
        address.zipOrPostcode = "CL0 WN4"
        
        deliveryDetails.address = address
        deliveryDetails.email = "g.clowney@clownmail.com"
        deliveryDetails.phone = "399945528234"

        order.deliveryDetails = deliveryDetails
        return order
    }
    
    func fakeCost() -> Cost {
        let lineItem = LineItem(id: 1, name: "item", cost: 20.0, formattedCost: "£20.00")
        let shippingMethod = ShippingMethod(id: 1, name: "Standard", shippingCostFormatted: "£4.99", totalCost: 4.99, totalCostFormatted: "£24.99", maxDeliveryTime: 10, minDeliveryTime: 3)
        
        return Cost(hash: 1, lineItems: [lineItem], shippingMethods: [shippingMethod], promoDiscount: nil, promoCodeInvalidReason: nil)
    }
    
    override func setUp() {
        PaymentAuthorizationManager.applePayMerchantId = "ClownMasterId"
        
        delegate = TestPaymentAuthorizationManagerDelegate()
        
        paymentAuthorizationManager = PaymentAuthorizationManager()
        paymentAuthorizationManager.basketOrder = fakeOrder()
        paymentAuthorizationManager.delegate = delegate
    }
    
    func testAuthorizePayment_applePay_shouldCrashWithoutMerchantId() {
        PaymentAuthorizationManager.applePayMerchantId = nil

        expectFatalError(expectedMessage: "Missing merchant ID for ApplePay: PhotobookSDK.shared.applePayMerchantID") {
            self.paymentAuthorizationManager.authorizePayment(cost: self.fakeCost(), method: .applePay)
        }
    }
    
    func testAuthorizePayment_applePay_shouldPresentAuthorizationController() {
        paymentAuthorizationManager.authorizePayment(cost: fakeCost(), method: .applePay)

        XCTAssertTrue(delegate.viewControllerToPresent != nil && delegate.viewControllerToPresent! is PKPaymentAuthorizationViewController)
    }
    
    func testAuthorizePayment_payPal_shouldNotPresentControllerIfCostIsMissing() {
        let lineItem = LineItem(id: 1, name: "item", cost: 20.0, formattedCost: "£20.00")
        let cost =  Cost(hash: 1, lineItems: [lineItem], shippingMethods: nil, promoDiscount: nil, promoCodeInvalidReason: nil)
        
        paymentAuthorizationManager.authorizePayment(cost: cost, method: .payPal)
    }
    
    func testAuthorizePayment_payPal_shouldPresentPaypalController() {
        paymentAuthorizationManager.authorizePayment(cost: fakeCost(), method: .payPal)
        
        XCTAssertTrue(delegate.viewControllerToPresent != nil)
    }
}
