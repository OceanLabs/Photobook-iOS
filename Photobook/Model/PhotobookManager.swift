//
//  PhotobookManager.swift
//  Photobook
//
//  Created by Julian Gruber on 19/03/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

/// Shared manager for the photo book UI
class PhotobookManager: NSObject {
    
    enum Tab: Int {
        case stories
        case browse
        case instagram
        case facebook
    }
    
    static func setupPayments() {
        PaymentAuthorizationManager.applePayPayTo = "Canon"
        PaymentAuthorizationManager.applePayMerchantId = "merchant.ly.kite.sdk"
        PaymentAuthorizationManager.stripeTestPublicKey = "pk_test_fJtOj7oxBKrLFOneBFLj0OH3"
        PaymentAuthorizationManager.stripeLivePublicKey = "pk_live_qQhXxzjS8inja3K31GDajdXo"
    }
    
    static func rootViewControllerForCurrentState() -> UIViewController {
        let tabBarController = photobookMainStoryboard.instantiateViewController(withIdentifier: "TabBarController") as! UITabBarController
        let isProcessingOrder = OrderProcessingManager.shared.isProcessingOrder
        
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
            receiptViewController.order = OrderManager.shared.loadBasketOrder()
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
    
    private static func configureTabBarController(_ tabBarController: UITabBarController) {
        
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
