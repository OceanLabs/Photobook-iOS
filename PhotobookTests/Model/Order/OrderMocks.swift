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
    
    override init() {
        super.init()
    }
}

class PaymentAuthorizationManagerDelegateMock: UIViewController {
    var viewControllerToPresent: UIViewController?
}

extension PaymentAuthorizationManagerDelegateMock: PaymentAuthorizationManagerDelegate {
    
    func costUpdated() {}    
    func paymentAuthorizationManagerUpdatedDetails() {}
    func paymentAuthorizationDidFinish(token: String?, error: Error?, completionHandler: ((PKPaymentAuthorizationStatus) -> Void)?) {}
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
    
    func progressDidUpdate() {}
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
