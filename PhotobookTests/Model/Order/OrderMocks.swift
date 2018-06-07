//
//  OrderMocks.swift
//  PhotobookTests
//
//  Created by Jaime Landazuri on 05/06/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import Foundation
import PassKit
@testable import Photobook

class TestOrder: Order {
    override var orderDescription: String {
        return "Order Description"
    }
}

class TestPaymentAuthorizationManagerDelegate: UIViewController {
    var viewControllerToPresent: UIViewController?
}

extension TestPaymentAuthorizationManagerDelegate: PaymentAuthorizationManagerDelegate {
    
    func costUpdated() {}
    
    func paymentAuthorizationDidFinish(token: String?, error: Error?, completionHandler: ((PKPaymentAuthorizationStatus) -> Void)?) {
        
    }
    
    func modalPresentationDidFinish() {}
    
    func modalPresentationWillBegin() {}
    
    override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        self.viewControllerToPresent = viewControllerToPresent
    }
}

class TestOrderSummaryManagerDelegate: OrderSummaryManagerDelegate {
    
    var calledWillUpdate = false
    var calledDidSetPreviewImageUrl = false
    var calledFailedToSetPreviewImageUrl = false
    
    var summary: OrderSummary?
    var upsellOption: UpsellOption?
    var error: Error?
    
    func orderSummaryManagerWillUpdate() {
        calledWillUpdate = true
    }
    
    func orderSummaryManagerDidSetPreviewImageUrl() {
        calledDidSetPreviewImageUrl = true
    }
    
    func orderSummaryManagerFailedToSetPreviewImageUrl() {
        calledFailedToSetPreviewImageUrl = true
    }
    
    func orderSummaryManagerDidUpdate(_ summary: OrderSummary?, error: Error?) {
        self.summary = summary
        self.error = error
    }
    
    func orderSummaryManagerFailedToApply(_ upsell: UpsellOption, error: Error?) {
        self.upsellOption = upsell
        self.error = error
    }
}
