//
//  PhotobookManager.swift
//  Photobook
//
//  Created by Julian Gruber on 19/03/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

let photobookBundle = Bundle(for: Photobook.self)
let photobookMainStoryboard =  UIStoryboard.init(name: "Main", bundle: photobookBundle)

/// Shared manager for the photo book UI
@objc public class PhotobookManager: NSObject {
    
    enum Tab: Int {
        case stories
        case browse
        case instagram
        case facebook
    }
    
    /// Shared client
    public static let shared = PhotobookManager()
    
    
    /// True if a photo book order is being processed, false otherwise
    public var isProcessingOrder: Bool {
        return OrderProcessingManager.shared.isProcessingOrder
    }
    
    /// Photo book view controller initialised with the provided images
    ///
    /// - Parameter assets: Images to use to initialise the photo book. Available asset types are: ImageAsset, URLAsset & PhotosAsset
    /// - Returns: A photo book view controller
    public func photobookViewController(with assets: [PhotobookAsset]) -> UIViewController {
        guard let assets = assets as? [Asset] else {
            fatalError("Could not initialise the Photo Book.")
        }
        
        let photobookViewController = photobookMainStoryboard.instantiateViewController(withIdentifier: "PhotobookViewController") as! PhotobookViewController
        photobookViewController.assets = assets
        
        return photobookViewController
    }
    
    /// Receipt View Controller
    ///
    /// - Parameter closure: Closure to call when the receipt view controller finishes its tasks or the user dismisses it
    /// - Returns: A receipt view controller
    public func receiptViewController(onDismiss closure: @escaping (() -> Void)) -> UIViewController? {
        guard isProcessingOrder else { return nil }
        
        let receiptViewController = photobookMainStoryboard.instantiateViewController(withIdentifier: "ReceiptTableViewController") as! ReceiptTableViewController
        receiptViewController.dismissClosure = closure
        
        return receiptViewController
    }
    
    /// Restores the user's photo book, if it exists, and any ongoing upload tasks
    ///
    /// - Parameter completionHandler: Completion handler to be forwarded from 'handleEventsForBackgroundURLSession' in the application's app delegate
    public func restorePhotobook(_ completionHandler: @escaping (() -> Void)) {
        ProductManager.shared.loadUserPhotobook(completionHandler)
    }
    
    func rootViewControllerForCurrentState() -> UIViewController {
        let tabBarController = photobookMainStoryboard.instantiateViewController(withIdentifier: "TabBarController") as! UITabBarController
        
        if IntroViewController.userHasDismissed && !isProcessingOrder {
            configureTabBarController(tabBarController)
            return tabBarController
        }
        
        let rootNavigationController = UINavigationController(navigationBarClass: PhotobookNavigationBar.self, toolbarClass: nil)
        rootNavigationController.isNavigationBarHidden = true
        if #available(iOS 11.0, *) {
            // Large titles on nav vc containing other nav vcs causes issues
            rootNavigationController.navigationBar.prefersLargeTitles = false
        }
        
        if !IntroViewController.userHasDismissed {
            let introViewController = photobookMainStoryboard.instantiateViewController(withIdentifier: "IntroViewController") as! IntroViewController
            introViewController.dismissClosure = {
                self.configureTabBarController(tabBarController)
                introViewController.proceedToTabBarController()
            }
            rootNavigationController.viewControllers = [introViewController]
            
        } else if isProcessingOrder {
            // Show receipt screen to prevent user from ordering another photobook
            let receiptViewController = photobookMainStoryboard.instantiateViewController(withIdentifier: "ReceiptTableViewController") as! ReceiptTableViewController
            receiptViewController.dismissClosure = {
                self.configureTabBarController(tabBarController)
                rootNavigationController.isNavigationBarHidden = true
                receiptViewController.proceedToTabBarController()
            }
            rootNavigationController.isNavigationBarHidden = false
            rootNavigationController.viewControllers = [receiptViewController]
        }
        
        return rootNavigationController
    }
    
    private func configureTabBarController(_ tabBarController: UITabBarController) {
        
        // Browse
        // Set the albumManager to the AlbumsCollectionViewController
        let albumViewController = (tabBarController.viewControllers?[Tab.browse.rawValue] as? UINavigationController)?.topViewController as? AlbumsCollectionViewController
        albumViewController?.albumManager = PhotosAlbumManager()
        
        // Stories
        // If there are no stories, remove the stories tab
        StoriesManager.shared.loadTopStories(completionHandler: {
            if StoriesManager.shared.stories.isEmpty {
                tabBarController.viewControllers?.remove(at: Tab.stories.rawValue)
            }
        })
        
        // Load the products here, so that the user avoids a loading screen on PhotobookViewController
        ProductManager.shared.initialise(completion: nil)        
    }
}
