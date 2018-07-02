//
//  PhotobookManager.swift
//  Photobook
//
//  Created by Julian Gruber on 19/03/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit
import Stripe
import PayPalDynamicLoader

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
        PaymentAuthorizationManager.applePayPayTo = "Kite.ly (via HD Photobooks)"
        PaymentAuthorizationManager.applePayMerchantId = "merchant.ly.kite.sdk"
        PhotobookAPIManager.apiKey = "57c832e42dfdda93d072c6a42c41fbcddf100805"
        KiteAPIClient.shared.apiKey = "57c832e42dfdda93d072c6a42c41fbcddf100805" //Live: ad6635a2c5f284956df20e78ae89a4e5efa46806
        Stripe.setDefaultPublishableKey("pk_test_FxzXniUJWigFysP0bowWbuy3")
        OLPayPalWrapper.initializeWithClientIds(forEnvironments: ["sandbox" : "AcEcBRDxqcCKiikjm05FyD4Sfi4pkNP98AYN67sr3_yZdBe23xEk0qhdhZLM"])
        OLPayPalWrapper.preconnect(withEnvironment: "sandbox") /*PayPalEnvironmentSandbox*/
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
            let receiptViewController = photobookMainStoryboard.instantiateViewController(withIdentifier: "ReceiptTableViewController") as! ReceiptTableViewController
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
