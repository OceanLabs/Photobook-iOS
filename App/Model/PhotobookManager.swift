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
    
    static let shared = PhotobookManager()
    
    enum Tab: Int {
        case stories
        case browse
        case instagram
        case facebook
    }
    
    func setupPayments() {
        let apiKey = KiteAPIClient.environment == .live ? Configuration.kiteApiClientLiveKey : Configuration.kiteApiClientTestKey
        PaymentAuthorizationManager.applePayPayTo = Configuration.applePayPayToString
        PaymentAuthorizationManager.applePayMerchantId = Configuration.applePayMerchantId
        PhotobookAPIManager.apiKey = apiKey
        KiteAPIClient.shared.apiKey = apiKey
    }
    
    func rootViewControllerForCurrentState() -> UIViewController {
        let isProcessingOrder = OrderManager.shared.isProcessingOrder
        ProductManager.shared.delegate = self
        
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
            receiptViewController.dismissClosure = { [weak welf = self] viewController in
                guard let stelf = welf else { return }
                let tabBarController = mainStoryboard.instantiateViewController(withIdentifier: "TabBarController") as! UITabBarController
                stelf.configureTabBarController(tabBarController)
                let dismissSegue = IntroDismissSegue(identifier: "ReceiptDismiss", source: viewController, destination: tabBarController)
                dismissSegue.perform()
            }
            rootNavigationController.viewControllers = [receiptViewController]
        }
        
        return rootNavigationController
    }
    
    func configureTabBarController(_ tabBarController: UITabBarController) {
        
        // Browse
        // Set the albumManager to the AlbumsCollectionViewController
        let albumViewController = (tabBarController.viewControllers?[Tab.browse.rawValue] as? UINavigationController)?.topViewController as? AlbumsCollectionViewController
        albumViewController?.albumManager = PhotosAlbumManager()
        
        // Attempt to restore photobook backup
        if let backup = PhotobookProductBackupManager.shared.restoreBackup() {
            ProductManager.shared.currentProduct = backup.product
            
            let photobookViewController = photobookMainStoryboard.instantiateViewController(withIdentifier: "PhotobookViewController") as! PhotobookViewController
            photobookViewController.assets = backup.assets
            photobookViewController.album = backup.album
            photobookViewController.albumManager = backup.albumManager
            photobookViewController.completionClosure = { (photobookProduct) in
                OrderManager.shared.reset()
                OrderManager.shared.basketOrder.products = [photobookProduct]
                
                let checkoutViewController = photobookMainStoryboard.instantiateViewController(withIdentifier: "CheckoutViewController") as! CheckoutViewController
                photobookViewController.navigationController?.pushViewController(checkoutViewController, animated: true)
            }
            
            guard let browseNavigationViewController = tabBarController.viewControllers?[Tab.browse.rawValue] as? UINavigationController else { return }
            browseNavigationViewController.pushViewController(photobookViewController, animated: false)
            
            if let assetPickerViewController = browseNavigationViewController.viewControllers.first as? AlbumsCollectionViewController {
                photobookViewController.photobookDelegate = assetPickerViewController
            }
            
            tabBarController.selectedIndex = Tab.browse.rawValue
        }

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

extension PhotobookManager: PhotobookProductChangeDelegate {
    
    func didChangePhotobookProduct(_ photobookProduct: PhotobookProduct, assets: [Asset], album: Album?, albumManager: AlbumManager?) {
        let productBackup = PhotobookProductBackup()
        productBackup.product = photobookProduct
        productBackup.assets = assets
        productBackup.album = album
        productBackup.albumManager = albumManager

        PhotobookProductBackupManager.shared.saveBackup(productBackup)
    }
    
    func didDeletePhotobookProduct() {
        PhotobookProductBackupManager.shared.deleteBackup()
    }
}
