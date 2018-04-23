//
//  PhotobookSDK.swift
//  PhotobookSDK
//
//  Created by Jaime Landazuri on 06/04/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
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
        case .live:
            APIClient.environment = .live
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
    @objc public var kiteApiKey: String! { didSet { KiteAPIClient.shared.apiKey = kiteApiKey } }
    
    /// Shared client
    @objc public static let shared = PhotobookSDK()
    
    /// True if a photo book order is being processed, false otherwise
    @objc public var isProcessingOrder: Bool {
        return OrderManager.shared.isProcessingOrder
    }
    
    /// Photo book view controller initialised with the provided images
    ///
    /// - Parameter assets: Images to use to initialise the photobook. Cannot be empty. Available asset types are: ImageAsset, URLAsset & PhotosAsset.
    /// - Parameter onDismiss: Closure to execute when the Photobook UI is ready to be dismissed
    /// - Returns: A photobook UIViewController
    @objc public func photobookViewController(with assets: [PhotobookAsset], onDismiss: (() -> Void)? = nil) -> UIViewController? {
        guard let assets = assets as? [Asset], assets.count > 0 else {
            print("Photobook SDK: Photobook View Controller not initialised because the assets array passed is empty or nil.")
            return nil
        }
        
        guard KiteAPIClient.shared.apiKey != nil else {
            fatalError("Photobook SDK: Photobook View Controller not initialised because the Kite API key was not set. You can get this from the Kite Dashboard.")
        }
        
        UIFont.loadAllFonts()
        SDWebImageManager.shared().imageCache?.config.shouldCacheImagesInMemory = false
        
        let navigationController = PhotobookNavigationController(navigationBarClass: PhotobookNavigationBar.self, toolbarClass: nil)
        let photobookViewController = photobookMainStoryboard.instantiateViewController(withIdentifier: "PhotobookViewController") as! PhotobookViewController
        photobookViewController.assets = assets
        photobookViewController.dismissClosure = onDismiss
        photobookViewController.showCancelButton = true
        
        navigationController.viewControllers = [ photobookViewController ]
        
        return navigationController
    }
    
    /// Receipt View Controller
    ///
    /// - Parameter onDismiss: Closure to execute when the receipt UI is ready to be dismissed
    /// - Returns: A receipt UIViewController
    @objc public func receiptViewController(onDismiss: (() -> Void)? = nil) -> UIViewController? {
        guard isProcessingOrder else { return nil }
        
        guard KiteAPIClient.shared.apiKey != nil else {
            fatalError("Photobook SDK: Receipt View Controller not initialised because the Kite API key was not set. You can get this from the Kite Dashboard.")
        }
        
        UIFont.loadAllFonts()
        let receiptViewController = photobookMainStoryboard.instantiateViewController(withIdentifier: "ReceiptTableViewController") as! ReceiptTableViewController
        receiptViewController.dismissClosure = { (tabBarController) in onDismiss?() }
        return receiptViewController
    }
    
    /// Restores the user's photo book, if it exists, and any ongoing upload tasks
    ///
    /// - Parameter completionHandler: Completion handler to be forwarded from 'handleEventsForBackgroundURLSession' in the application's app delegate
    @objc public func restorePhotobook(_ completionHandler: @escaping (() -> Void)) {
        _ = OrderManager.shared.loadProcessingOrder()
        completionHandler()
    }
}
