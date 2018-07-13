//
//  PhotobookSDK.swift
//  PhotobookSDK
//
//  Created by Jaime Landazuri on 06/04/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit
import SDWebImage
import Stripe
import PayPalDynamicLoader

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
            Stripe.setDefaultPublishableKey("pk_test_FxzXniUJWigFysP0bowWbuy3")
            OLPayPalWrapper.initializeWithClientIds(forEnvironments: ["sandbox" : "AcEcBRDxqcCKiikjm05FyD4Sfi4pkNP98AYN67sr3_yZdBe23xEk0qhdhZLM"])
            OLPayPalWrapper.preconnect(withEnvironment: "sandbox") /*PayPalEnvironmentSandbox*/
        case .live:
            APIClient.environment = .live
            Stripe.setDefaultPublishableKey("pk_live_o1egYds0rWu43ln7FjEyOU5E")
            OLPayPalWrapper.initializeWithClientIds(forEnvironments: ["live" : "ASYVBBCHF_KwVUstugKy4qvpQaPlUeE_5beKRJHpIP2d3SA_jZrsaUDTmLQY"])
            OLPayPalWrapper.preconnect(withEnvironment: "live") /*PayPalEnvironmentProduction*/
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
            if let firstViewController = photobookViewController.navigationController?.viewControllers.first {
                photobookViewController.navigationController?.setViewControllers([firstViewController, checkoutViewController], animated: true)
            }
        }

        let viewControllerToReturn: UIViewController
        if embedInNavigation {
            let navigationController = PhotobookNavigationController(navigationBarClass: PhotobookNavigationBar.self, toolbarClass: nil)
            navigationController.viewControllers = [ photobookViewController ]
            viewControllerToReturn = navigationController
        } else {
            viewControllerToReturn = photobookViewController
        }
        
        return viewControllerToReturn
    }
    
    /// Receipt View Controller
    ///
    /// - Parameter onDismiss: Closure to execute when the receipt UI is ready to be dismissed
    /// - Returns: A receipt UIViewController
    @objc public func receiptViewController(delegate: DismissDelegate? = nil) -> UIViewController? {
        guard isProcessingOrder else { return nil }
        
        guard KiteAPIClient.shared.apiKey != nil else {
            fatalError("Photobook SDK: Receipt View Controller not initialised because the Kite API key was not set. You can get this from the Kite Dashboard.")
        }
        
        UIFont.loadAllFonts()
        let receiptViewController = photobookMainStoryboard.instantiateViewController(withIdentifier: "ReceiptTableViewController") as! ReceiptTableViewController
        receiptViewController.order = OrderManager.shared.processingOrder
        receiptViewController.dismissDelegate = delegate
        return receiptViewController
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
        if embedInNavigation {
            let navigationController = PhotobookNavigationController(navigationBarClass: PhotobookNavigationBar.self, toolbarClass: nil)
            navigationController.viewControllers = [ checkoutViewController ]
            return navigationController
        } else {
            return checkoutViewController
        }
        
    }
}
