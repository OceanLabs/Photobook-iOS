//
//  PhotobookSDK.swift
//  PhotobookSDK
//
//  Created by Jaime Landazuri on 06/04/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

/// Shared manager for the photo book UI
@objc public class PhotobookSDK: NSObject {
    
    @objc public static let orderWasCreatedNotificationName = OrdersNotificationName.orderWasCreated
    @objc public static let orderWasSuccessfulNotificationName = OrdersNotificationName.orderWasSuccessful
    
    @objc public enum Environment: Int {
        case test
        case live
    }
    
    /// Set to use the live or test environment
    @objc public static func setEnvironment(environment: Environment) {
        switch environment {
        case .test:
            PhotobookManager.environment = .test
        case .live:
            PhotobookManager.environment = .live
        }
    }
    
    /// Shared client
    @objc public static let shared = PhotobookSDK()
    
    
    /// True if a photo book order is being processed, false otherwise
    @objc public var isProcessingOrder: Bool {
        return OrderProcessingManager.shared.isProcessingOrder
    }
    
    /// Photo book view controller initialised with the provided images
    ///
    /// - Parameter assets: Images to use to initialise the photobook. Cannot be empty. Available asset types are: ImageAsset, URLAsset & PhotosAsset.
    /// - Parameter delegate: Delegate to dismiss the photobook creation UI
    /// - Returns: A photobook UIViewController
    @objc public func photobookViewController(with assets: [PhotobookAsset], delegate: PhotobookSdkDelegate? = nil) -> UIViewController? {
        guard let assets = assets as? [Asset], assets.count > 0 else {
            return nil
        }
        
        UIFont.loadAllFonts()
        let navigationController = UINavigationController(navigationBarClass: PhotobookNavigationBar.self, toolbarClass: nil)
        let photobookViewController = photobookMainStoryboard.instantiateViewController(withIdentifier: "PhotobookViewController") as! PhotobookViewController
        photobookViewController.assets = assets
        photobookViewController.delegate = delegate
        
        let closeBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: photobookViewController, action: #selector(photobookViewController.tappedCancel(_:)))
        photobookViewController.navigationItem.leftBarButtonItems = [ closeBarButtonItem ]
        
        navigationController.viewControllers = [ photobookViewController ]
        
        return navigationController
    }
    
    /// Receipt View Controller
    ///
    /// - Parameter closure: Closure to call when the receipt view controller finishes its tasks or the user dismisses it
    /// - Returns: A receipt UIViewController
    @objc public func receiptViewController(onDismiss closure: @escaping (() -> Void)) -> UIViewController? {
        guard isProcessingOrder else { return nil }
        
        UIFont.loadAllFonts()
        let receiptViewController = photobookMainStoryboard.instantiateViewController(withIdentifier: "ReceiptTableViewController") as! ReceiptTableViewController
        receiptViewController.dismissClosure = closure
        
        return receiptViewController
    }
    
    /// Restores the user's photo book, if it exists, and any ongoing upload tasks
    ///
    /// - Parameter completionHandler: Completion handler to be forwarded from 'handleEventsForBackgroundURLSession' in the application's app delegate
    @objc public func restorePhotobook(_ completionHandler: @escaping (() -> Void)) {
        ProductManager.shared.loadUserPhotobook(completionHandler)
    }
}
