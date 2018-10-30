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

import UIKit
import SDWebImage

/// Shared manager for the photo book UI
@objc public class PhotobookSDK: NSObject {
    
    @objc public static let orderWasCreatedNotificationName = OrdersNotificationName.orderWasCreated
    @objc public static let orderWasSuccessfulNotificationName = OrdersNotificationName.orderWasSuccessful
    
    @objc public enum Environment: Int {
        case test
        case live
    }
    
    /// Set to use the live or test environment
    @objc public func setEnvironment(environment: Environment) {
        switch environment {
        case .test:
            APIClient.environment = .test
            KiteAPIClient.environment = .test
        case .live:
            APIClient.environment = .live
            KiteAPIClient.environment = .live
        }
    }
    
    /// Payee name to use for ApplePay
    @objc public var applePayPayTo: String? {
        didSet {
            if let applePayPayTo = applePayPayTo {
                PaymentAuthorizationManager.applePayPayTo = applePayPayTo
            }
        }
    }
    
    /// ApplePay merchand ID
    @objc public var applePayMerchantId: String! { didSet { PaymentAuthorizationManager.applePayMerchantId = applePayMerchantId } }
    
    /// Kite public API key
    @objc public var kiteApiKey: String! {
        didSet {
            PhotobookAPIManager.apiKey = kiteApiKey
            KiteAPIClient.shared.apiKey = kiteApiKey
        }
    }
    
    /// Shared client
    @objc public static let shared: PhotobookSDK = {
        let sdk = PhotobookSDK()
        sdk.setEnvironment(environment: .live)
        return sdk
    }()
    
    /// True if a photo book order is being processed, false otherwise
    @objc public var isProcessingOrder: Bool {
        return OrderManager.shared.isProcessingOrder
    }
    
    /// Photo book view controller initialised with the provided images
    ///
    /// - Parameter photobookAssets: Images to use to initialise the photo book. Cannot be empty.
    /// - Parameter embedInNavigation: Whether the returned view controller should be a UINavigationController. Defaults to false. Note that a navigation controller must be provided if false.
    /// - Parameter delegate: Delegate that can handle the dismissal of the photo book and also provide a custom photo picker
    /// - Returns: A photobook UIViewController
    @objc public func photobookViewController(with photobookAssets: [PhotobookAsset], embedInNavigation: Bool = false, delegate: PhotobookDelegate? = nil) -> UIViewController? {
        
        // Return the upload / receipt screen if there is an order in progress
        guard !isProcessingOrder else {
            return receiptViewController(delegate: delegate)
        }
        
        guard !photobookAssets.isEmpty else {
            print("Photobook SDK: Photobook View Controller not initialised because the assets array passed is empty.")
            return nil
        }
        
        guard KiteAPIClient.shared.apiKey != nil else {
            fatalError("Photobook SDK: Photobook View Controller not initialised because the Kite API key was not set. You can get this from the Kite Dashboard.")
        }

        UIFont.loadAllFonts()
        SDWebImageManager.shared().imageCache?.config.shouldCacheImagesInMemory = false
        
        if ProcessInfo.processInfo.arguments.contains("UITESTINGENVIRONMENT") {
            OrderManager.shared.cancelProcessing {}
            OrderManager.shared.basketOrder.deliveryDetails = nil
            UserDefaults.standard.removeObject(forKey: "ly.kite.sdk.savedDetailsKey")
            UserDefaults.standard.removeObject(forKey: "ly.kite.sdk.savedAddressesKey")
            UserDefaults.standard.synchronize()
        }
        
        let photobookViewController = photobookMainStoryboard.instantiateViewController(withIdentifier: "PhotobookViewController") as! PhotobookViewController
        photobookViewController.assets = PhotobookAsset.assets(from: photobookAssets)
        photobookViewController.photobookDelegate = delegate
        photobookViewController.completionClosure = { (photobookProduct) in
            Checkout.shared.addProductToBasket(photobookProduct)
            ProductManager.shared.reset()
            
            let checkoutViewController = photobookMainStoryboard.instantiateViewController(withIdentifier: "CheckoutViewController") as! CheckoutViewController
            checkoutViewController.dismissDelegate = delegate
            if let firstViewController = photobookViewController.navigationController?.viewControllers.first {
                photobookViewController.navigationController?.setViewControllers([firstViewController, checkoutViewController], animated: true)
            }
        }

        return embedInNavigation ? embedViewControllerInNavigation(photobookViewController) : photobookViewController
    }
    
    /// Receipt View Controller
    ///
    /// - Parameters:
    ///   - embedInNavigation: Whether the returned view controller should be a UINavigationController. Defaults to false. Note that a navigation controller must be provided if false.
    ///   - delegate: Closure to execute when the receipt UI is ready to be dismissed
    /// - Returns: A receipt UIViewController
    @objc public func receiptViewController(embedInNavigation: Bool = false, delegate: DismissDelegate? = nil) -> UIViewController? {
        guard isProcessingOrder else { return nil }
        
        guard KiteAPIClient.shared.apiKey != nil else {
            fatalError("Photobook SDK: Receipt View Controller not initialised because the Kite API key was not set. You can get this from the Kite Dashboard.")
        }
        
        UIFont.loadAllFonts()
        let receiptViewController = photobookMainStoryboard.instantiateViewController(withIdentifier: "ReceiptViewController") as! ReceiptViewController
        receiptViewController.order = OrderManager.shared.processingOrder
        receiptViewController.dismissDelegate = delegate

        return embedInNavigation ? embedViewControllerInNavigation(receiptViewController) : receiptViewController
    }
    
    
    /// Checkout View Controller
    ///
    /// - Parameters:
    ///   - embedInNavigation: Whether the returned view controller should be a UINavigationController. Defaults to false. Note that a navigation controller must be provided if false.
    ///   - delegate: Delegate that can handle the dismissal
    /// - Returns: A checkout ViewController
    @objc public func checkoutViewController(embedInNavigation: Bool = false, delegate: DismissDelegate? = nil) -> UIViewController? {
        guard OrderManager.shared.basketOrder.products.count > 0 else { return nil }
        
        guard KiteAPIClient.shared.apiKey != nil else {
            fatalError("Photobook SDK: Receipt View Controller not initialised because the Kite API key was not set. You can get this from the Kite Dashboard.")
        }
        
        let checkoutViewController = photobookMainStoryboard.instantiateViewController(withIdentifier: "CheckoutViewController") as! CheckoutViewController
        checkoutViewController.dismissDelegate = delegate
        
        return embedInNavigation ? embedViewControllerInNavigation(checkoutViewController) : checkoutViewController
    }
    
    private func embedViewControllerInNavigation(_ viewController: UIViewController) -> PhotobookNavigationController {
        let navigationController = PhotobookNavigationController(navigationBarClass: PhotobookNavigationBar.self, toolbarClass: nil)
        navigationController.viewControllers = [ viewController ]
        return navigationController
    }
}
