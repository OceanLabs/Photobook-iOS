//
//  PhotobookManager.swift
//  Photobook
//
//  Created by Julian Gruber on 19/03/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

let mainStoryboard =  UIStoryboard(name: "Main", bundle: nil)

/// Shared manager for the photo book UI
class PhotobookManager: NSObject {
    
    enum Tab: Int {
        case stories
        case browse
        case instagram
        case facebook
    }
    
    static func setupPayments() {
        PaymentAuthorizationManager.applePayPayTo = Configuration.applePayPayToString
        PaymentAuthorizationManager.applePayMerchantId = Configuration.applePayMerchantId
        PhotobookAPIManager.apiKey = Configuration.kiteApiClientKey
        KiteAPIClient.shared.apiKey = Configuration.kiteApiClientKey
    }
    
    static func rootViewControllerForCurrentState() -> UIViewController {
        let isProcessingOrder = OrderManager.shared.isProcessingOrder
        
        if IntroViewController.userHasDismissed && !isProcessingOrder {
            let tabBarController = mainStoryboard.instantiateViewController(withIdentifier: "TabBarController") as! UITabBarController
            configureTabBarController(tabBarController)
            return tabBarController
        }
        
        let rootNavigationController = PhotobookNavigationController(navigationBarClass: PhotobookNavigationBar.self, toolbarClass: nil)
        if #available(iOS 11.0, *) {
            // Large titles on nav vc containing other nav vcs causes issues
            rootNavigationController.navigationBar.prefersLargeTitles = false
        }
        
        if !IntroViewController.userHasDismissed {
            rootNavigationController.isNavigationBarHidden = true
            let introViewController = mainStoryboard.instantiateViewController(withIdentifier: "IntroViewController") as! IntroViewController
            rootNavigationController.viewControllers = [introViewController]
            
        } else if isProcessingOrder {
            // Show receipt screen to prevent user from ordering another photobook
            let receiptViewController = photobookMainStoryboard.instantiateViewController(withIdentifier: "ReceiptViewController") as! ReceiptViewController
            receiptViewController.order = OrderManager.shared.processingOrder
            receiptViewController.dismissClosure = { viewController in
                let tabBarController = mainStoryboard.instantiateViewController(withIdentifier: "TabBarController") as! UITabBarController
                configureTabBarController(tabBarController)
                let dismissSegue = IntroDismissSegue(identifier: "ReceiptDismiss", source: viewController, destination: tabBarController)
                dismissSegue.perform()
            }
            rootNavigationController.viewControllers = [receiptViewController]
        }
        
        return rootNavigationController
    }
    
    static func configureTabBarController(_ tabBarController: UITabBarController) {
        
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
        if NSClassFromString("XCTest") == nil {
            ProductManager.shared.initialise(completion: nil)
        }
    }
    
}
