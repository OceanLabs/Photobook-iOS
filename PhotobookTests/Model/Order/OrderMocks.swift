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
