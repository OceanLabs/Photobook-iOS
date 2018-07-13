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

class OrderMock: Order {
    var orderParametersStub: [String: Any]?
    
    override var orderDescription: String {
        return "Order Description"
    }
    
    override func orderParameters() -> [String: Any]? {
        return orderParametersStub
    }
}

class PaymentAuthorizationManagerDelegateMock: UIViewController {
    var viewControllerToPresent: UIViewController?
}

extension PaymentAuthorizationManagerDelegateMock: PaymentAuthorizationManagerDelegate {
    
    func costUpdated() {}
    
    func paymentAuthorizationDidFinish(token: String?, error: Error?, completionHandler: ((PKPaymentAuthorizationStatus) -> Void)?) {
        
    }
    
    func modalPresentationDidFinish() {}
    
    func modalPresentationWillBegin() {}
    
    override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        self.viewControllerToPresent = viewControllerToPresent
    }
}

class OrderSummaryManagerDelegateMock: OrderSummaryManagerDelegate {
    
    var calledWillUpdate = false
    var calledDidSetPreviewImageUrl = false
    var calledFailedToSetPreviewImageUrl = false
    
    var summary: OrderSummary?
    var upsellOption: UpsellOption?
    var error: ErrorMessage?
    
    func orderSummaryManagerWillUpdate() {
        calledWillUpdate = true
    }
    
    func orderSummaryManagerDidSetPreviewImageUrl() {
        calledDidSetPreviewImageUrl = true
    }
    
    func orderSummaryManagerFailedToSetPreviewImageUrl() {
        calledFailedToSetPreviewImageUrl = true
    }
    
    func orderSummaryManagerDidUpdate(_ summary: OrderSummary?, error: ErrorMessage?) {
        self.summary = summary
        self.error = error
    }
    
    func orderSummaryManagerFailedToApply(_ upsell: UpsellOption, error: ErrorMessage) {
        self.upsellOption = upsell
        self.error = error
    }
}

extension Notification.Name {
    static let orderDidComplete = Notification.Name("orderDidComplete")
}

class OrderProcessingDelegateMock: OrderProcessingDelegate {
    
    var didComplete: Bool = false
    var error: OrderProcessingError?
    
    func uploadStatusDidUpdate() {}    
    func orderWillFinish() {}
    
    func orderDidComplete(error: OrderProcessingError?) {
        NotificationCenter.default.post(name: .orderDidComplete, object: error)
        didComplete = true
        self.error = error
    }
}

class AssetLoadingManagerMock: AssetLoadingManager {
    
    var imageData: Data?
    var fileExtension: AssetDataFileExtension?
    var error: Error?
    
    override func imageData(for asset: Asset, progressHandler: ((Int64, Int64) -> Void)?, completionHandler: @escaping (Data?, AssetDataFileExtension, Error?) -> Void) {
        completionHandler(imageData, fileExtension!, error)
    }
}
