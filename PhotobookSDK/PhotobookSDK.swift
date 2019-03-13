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

struct AssetsNotificationName {
    static let albumsWereUpdated = Notification.Name("ly.kite.photobook.sdk.albumsWereUpdatedNotificationName")
}

@objc public class AlbumChange: NSObject {
    public var albumIdentifier: String!
    public var assetsRemoved: [PhotobookAsset]!
    public var assetsInserted: [PhotobookAsset]!
    public var indexesRemoved: [Int]!
    
    public init(albumIdentifier: String, assetsRemoved: [PhotobookAsset], assetsInserted: [PhotobookAsset], indexesRemoved: [Int]) {
        self.albumIdentifier = albumIdentifier
        self.assetsRemoved = assetsRemoved
        self.assetsInserted = assetsInserted
        self.indexesRemoved = indexesRemoved
    }
}

/// Shared manager for the photo book UI
@objc public class PhotobookSDK: NSObject {
    
    @objc public enum Environment: Int {
        case test
        case live
    }
    
    /// Set to use the live or test environment
    @objc public var environment: Environment = .live {
        didSet {
            switch environment {
            case .test:
                APIClient.environment = .test
                KiteAPIClient.environment = .test
            case .live:
                APIClient.environment = .live
                KiteAPIClient.environment = .live
            }
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
            PaymentAuthorizationManager.setPaymentKeys()
        }
    }
    
    /// Title of the button that finalises the photo book creation process. Displays "Add to Basket" by default.
    @objc public var ctaButtonTitle = NSLocalizedString("photobook/cta", value: "Add to Basket", comment: "Title for the CTA button")
    
    /// Shared client
    @objc public static let shared: PhotobookSDK = {
        let sdk = PhotobookSDK()
        sdk.environment = .live
        return sdk
    }()
    
    /// True if a photo book order is being processed, false otherwise
    @objc public var isProcessingOrder: Bool {
        return OrderManager.shared.isProcessingOrder
    }
    
    //// The minimum required number of photos to create a photo book
    @objc public var minimumRequiredPhotos: Int {
        return ProductManager.shared.minimumRequiredPages
    }

    /// The maximum allowed number of photos to create a photo book
    @objc public var maximumAllowedPhotos: Int {
        return ProductManager.shared.maximumAllowedPages
    }
    
    /// To be called from application(_: handleEventsForBackgroundURLSession: completionHandler:) when the app wakes up due to a background session update
    ///
    /// - Parameter completion: The completion closure forwarded by the application delegate
    @objc public func loadProcessingOrderAfterBackgroundRequest(_ completion: @escaping () -> Void) {
        _ = OrderManager.shared.loadProcessingOrder(completion)
    }
    
    /// Photo book view controller initialised with the provided images
    ///
    /// - Parameters:
    ///   - photobookAssets: Images to use to initialise the photo book. Cannot be empty.
    ///   - embedInNavigation: Whether the returned view controller should be a UINavigationController. Defaults to false. Note that a navigation controller must be provided if false.
    ///   - navigatesToCheckout: The photo book is added and the basket is presented by default. Set this flag to false to execute the completion closure when "Add to Basket" is tapped.
    ///   - delegate: Delegate that can provide a custom photo picker
    ///   - completion: Completion closure. Returns the view controller to be dismissed and whether the process was successful or not.
    /// - Returns: A photobook UIViewController
    @objc public func photobookViewController(with photobookAssets: [PhotobookAsset], embedInNavigation: Bool = false, navigatesToCheckout: Bool = true, delegate: PhotobookDelegate? = nil, completion: @escaping (_ source: UIViewController, _ success: Bool) -> ()) -> UIViewController? {
        // Load the products here, so that the user avoids a loading screen on PhotobookViewController
        ProductManager.shared.initialise(completion: nil)
        return photobookViewController(with: photobookAssets, embedInNavigation: embedInNavigation, navigatesToCheckout: navigatesToCheckout, delegate: delegate, useBackup: false, completion: completion)
    }
    
    /// Photo book view controller restored from a backup
    ///
    /// - Parameters:
    ///   - embedInNavigation: Whether the returned view controller should be a UINavigationController. Defaults to false. Note that a navigation controller must be provided if false.
    ///   - navigatesToCheckout: The photo book is added and the basket is presented by default. Set this flag to false to execute the completion closure when "Add to Basket" is tapped.
    ///   - delegate: Delegate that can provide a custom photo picker
    ///   - completion: Completion closure. Returns the view controller to be dismissed and whether the process was successful or not.
    /// - Returns: A photobook UIViewController
    @objc public func photobookViewControllerFromBackup(embedInNavigation: Bool = false, navigatesToCheckout: Bool = true, delegate: PhotobookDelegate? = nil, completion: @escaping (_ source: UIViewController, _ success: Bool) -> ()) -> UIViewController? {
        return photobookViewController(with: nil, embedInNavigation: embedInNavigation, navigatesToCheckout: navigatesToCheckout, delegate: delegate, useBackup: true, completion: completion)
    }
    
    private func photobookViewController(with photobookAssets: [PhotobookAsset]? = nil, embedInNavigation: Bool = false, navigatesToCheckout: Bool, delegate: PhotobookDelegate? = nil, useBackup: Bool = false, completion: @escaping (_ source: UIViewController, _ success: Bool) -> ()) -> UIViewController? {
        
        let dismissHandler: (_ source: UIViewController, _ success: Bool)->() = { source, success in
            let isReceipt = source as? ReceiptViewController != nil || (source as? UINavigationController)?.topViewController as? ReceiptViewController != nil
            guard success, !isReceipt else {
                completion(source, success)
                return
            }
            
            Checkout.shared.addCurrentProductToBasket()
            
            // Photobook completion
            if let checkoutViewController = PhotobookSDK.shared.checkoutViewController(embedInNavigation: false, dismissClosure: completion) {
                source.navigationController?.pushViewController(checkoutViewController, animated: true)
            }
        }
        
        let completionClosure = navigatesToCheckout ? dismissHandler : completion
        
        // Return the upload / receipt screen if there is an order in progress
        guard !isProcessingOrder else {
            return receiptViewController(dismissClosure: completion)
        }

        guard KiteAPIClient.shared.apiKey != nil else {
            fatalError("Photobook SDK: Photobook View Controller not initialised because the Kite API key was not set. You can get this from the Kite Dashboard.")
        }
        
        UIFont.loadAllFonts()
        SDWebImageManager.shared().imageCache?.config.shouldCacheImagesInMemory = false
        
        if ProcessInfo.processInfo.arguments.contains("UITESTINGENVIRONMENT") {
            OrderManager.shared.cancelProcessing {}
            OrderManager.shared.reset()
            UserDefaults.standard.removeObject(forKey: "ly.kite.sdk.savedDetailsKey")
            UserDefaults.standard.removeObject(forKey: "ly.kite.sdk.savedAddressesKey")
            UserDefaults.standard.synchronize()
            
            PhotobookProductBackupManager.shared.deleteBackup()
        }

        // Check if a back up is available
        var assets: [Asset]!
        if useBackup, let backup = PhotobookProductBackupManager.shared.restoreBackup() {
            ProductManager.shared.currentProduct = backup.product
            assets = backup.assets
        } else if let photobookAssets = photobookAssets, !photobookAssets.isEmpty {
            assets = PhotobookAsset.assets(from: photobookAssets)
        } else {
            print("Photobook SDK: Photobook View Controller not initialised because the assets array passed is empty.")
            return nil
        }
        
        let photobookViewController = photobookMainStoryboard.instantiateViewController(withIdentifier: "PhotobookViewController") as! PhotobookViewController
        photobookViewController.assets = assets
        photobookViewController.photobookDelegate = delegate
        photobookViewController.completionClosure = completionClosure
        
        return embedInNavigation ? embedViewControllerInNavigation(photobookViewController) : photobookViewController
    }
    
    /// Receipt View Controller
    ///
    /// - Parameters:
    ///   - embedInNavigation: Whether the returned view controller should be a UINavigationController. Defaults to false. Note that a navigation controller must be provided if false.
    ///   - dismissClosure: Closure called when the user wants to dismiss the receipt. Returns the view controller to be dismissed and whether the process was successful or not.
    /// - Returns: A receipt UIViewController
    @objc public func receiptViewController(embedInNavigation: Bool = false, dismissClosure: @escaping (_ source: UIViewController, _ success: Bool) -> ()) -> UIViewController? {
        guard isProcessingOrder else { return nil }
        
        guard KiteAPIClient.shared.apiKey != nil else {
            fatalError("Photobook SDK: Receipt View Controller not initialised because the Kite API key was not set. You can get this from the Kite Dashboard.")
        }        
        let receiptViewController = photobookMainStoryboard.instantiateViewController(withIdentifier: "ReceiptViewController") as! ReceiptViewController
        receiptViewController.order = OrderManager.shared.processingOrder
        receiptViewController.dismissClosure = dismissClosure

        return embedInNavigation ? embedViewControllerInNavigation(receiptViewController) : receiptViewController
    }
    
    /// Checkout View Controller
    ///
    /// - Parameters:
    ///   - embedInNavigation: Whether the returned view controller should be a UINavigationController. Defaults to false. Note that a navigation controller must be provided if false.
    ///   - dismissClosure: Closure called when the user wants to dismiss the receipt. Returns the view controller to be dismissed and whether the process was successful or not.
    /// - Returns: A checkout ViewController
    @objc public func checkoutViewController(embedInNavigation: Bool = false, dismissClosure: @escaping (_ source: UIViewController, _ success: Bool) -> ()) -> UIViewController? {
        
        guard KiteAPIClient.shared.apiKey != nil else {
            fatalError("Photobook SDK: Receipt View Controller not initialised because the Kite API key was not set. You can get this from the Kite Dashboard.")
        }
        
        let checkoutViewController = photobookMainStoryboard.instantiateViewController(withIdentifier: "CheckoutViewController") as! CheckoutViewController
        checkoutViewController.dismissClosure = dismissClosure
        
        return embedInNavigation ? embedViewControllerInNavigation(checkoutViewController) : checkoutViewController
    }

    /// Informs the SDK of assets being modified / deleted from an album
    ///
    /// - Parameter changes: Data structure containing details of the assets changed
    @objc public func albumsWereUpdated(_ changes: [AlbumChange]) {
        NotificationCenter.default.post(name: AssetsNotificationName.albumsWereUpdated, object: changes)
    }
    
    /// Requests the image for a photo library asset via the SDK's caching system
    ///
    /// - Parameters:
    ///   - asset: Asset
    ///   - size: Size
    ///   - completion: Completion closure
    @objc public func cachedImage(for asset: PhotobookAsset, size: CGSize, completion: @escaping (UIImage?, Error?) -> ()) {
        guard let asset = PhotobookAsset.assets(from: [asset])?.first else {
            completion(nil, AssetLoadingException.notFound)
            return
        }        
        AssetLoadingManager.shared.image(for: asset, size: size, loadThumbnailFirst: true, progressHandler: nil, completionHandler: completion)
    }
    
    private func embedViewControllerInNavigation(_ viewController: UIViewController) -> PhotobookNavigationController {
        let navigationController = PhotobookNavigationController(navigationBarClass: PhotobookNavigationBar.self, toolbarClass: nil)
        navigationController.viewControllers = [ viewController ]
        return navigationController
    }
}
