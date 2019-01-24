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
import Photobook

let mainStoryboard =  UIStoryboard(name: "Main", bundle: nil)

/// Shared manager for the photo book UI
class PhotobookManager: NSObject {
    
    static let shared = PhotobookManager()
    lazy var selectedAssetsManager = SelectedAssetsManager()
    
    enum Tab: Int {
        case stories
        case browse
        case instagram
        case facebook
    }
    
    func setup() {
        var environment = PhotobookSDK.Environment.live
        #if TEST_ENVIRONMENT
        environment = .test
        #endif

        PhotobookSDK.shared.environment = environment
        PhotobookSDK.shared.applePayMerchantId = Configuration.applePayMerchantId
        PhotobookSDK.shared.applePayPayTo = Configuration.applePayPayToString
        PhotobookSDK.shared.kiteApiKey = environment == .live ? Configuration.kiteApiClientLiveKey : Configuration.kiteApiClientTestKey
        PhotobookSDK.shared.ctaButtonTitle = NSLocalizedString("OrderSummary/cta", value: "Continue", comment: "Title for the CTA button")
    }
    
    func rootViewControllerForCurrentState() -> UIViewController {
        let isProcessingOrder = PhotobookSDK.shared.isProcessingOrder

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
            let receiptViewController = PhotobookSDK.shared.receiptViewController(embedInNavigation: false) { [weak welf = self] viewController, success in
                AssetDataSourceBackupManager.shared.deleteBackup()

                guard let stelf = welf else { return }
                let tabBarController = mainStoryboard.instantiateViewController(withIdentifier: "TabBarController") as! UITabBarController
                stelf.configureTabBarController(tabBarController)
                let dismissSegue = ReceiptDismissSegue(identifier: "ReceiptDismiss", source: viewController, destination: tabBarController)
                dismissSegue.perform()
            }
            
            rootNavigationController.viewControllers = receiptViewController != nil ? [receiptViewController!] : [UIViewController()]
        }
        
        return rootNavigationController
    }
    
    func configureTabBarController(_ tabBarController: UITabBarController) {
        
        // Attempt to restore picker data source and photobook backups
        if let (selectedNavigationController, photobookDelegate) = restoreAssetDataSourceBackup(tabBarController),
           let photobookViewController = PhotobookSDK.shared.photobookViewControllerFromBackup(embedInNavigation: false, navigatesToCheckout: false, delegate: photobookDelegate, completion: {
            (viewController, success) in
            
            guard success else {
                AssetDataSourceBackupManager.shared.deleteBackup()
                
                if let tabBar = viewController.tabBarController?.tabBar {
                    tabBar.isHidden = false
                }
                
                viewController.navigationController?.popViewController(animated: true)
                return
            }
            
            let items = Checkout.shared.numberOfItemsInBasket()
            if items == 0 {
                Checkout.shared.addCurrentProductToBasket()
            } else {
                // Only allow one item in the basket
                Checkout.shared.clearBasketOrder()
                Checkout.shared.addCurrentProductToBasket(items: items)
            }
            
            // Push the checkout on completion
            if let checkoutViewController = PhotobookSDK.shared.checkoutViewController(embedInNavigation: false, dismissClosure: { viewController, success in
                AssetDataSourceBackupManager.shared.deleteBackup()
                
                viewController.navigationController?.popToRootViewController(animated: true)
                if success {
                    NotificationCenter.default.post(name: SelectedAssetsManager.notificationNamePhotobookComplete, object: nil)
                }
            }) {
                selectedNavigationController.pushViewController(checkoutViewController, animated: true)
            }
        }) {
            selectedNavigationController.pushViewController(photobookViewController, animated: false)
        }
    }
    
    private func removeStoriesTabIfNeeded(_ tabBarController: UITabBarController) {
        StoriesManager.shared.loadTopStories(completionHandler: {
            if StoriesManager.shared.stories.isEmpty {
                tabBarController.viewControllers?.remove(at: Tab.stories.rawValue)
            }
        })
    }
    
    private func restoreAssetDataSourceBackup(_ tabBarController: UITabBarController) -> (UINavigationController, PhotobookDelegate)? {
        var selectedNavigationController: UINavigationController
        var photobookDelegate: PhotobookDelegate
        
        guard let dataSourceBackup = AssetDataSourceBackupManager.shared.restoreBackup() else {
            removeStoriesTabIfNeeded(tabBarController)
            return nil
        }
        
        if let _ = dataSourceBackup.albumManager as? FacebookAlbumManager {
            selectedNavigationController = tabBarController.viewControllers?[Tab.facebook.rawValue] as! UINavigationController
            tabBarController.selectedIndex = Tab.facebook.rawValue
            
            let facebookAlbumsCollectionViewController = AlbumsCollectionViewController.facebookAlbumsCollectionViewController()
            facebookAlbumsCollectionViewController.assetPickerDelegate = facebookAlbumsCollectionViewController
            selectedNavigationController.setViewControllers([facebookAlbumsCollectionViewController], animated: false)
            removeStoriesTabIfNeeded(tabBarController)
            
            photobookDelegate = facebookAlbumsCollectionViewController
        } else if let _ = dataSourceBackup.albumManager as? PhotosAlbumManager {
            selectedNavigationController = tabBarController.viewControllers?[Tab.browse.rawValue] as! UINavigationController
            tabBarController.selectedIndex = Tab.browse.rawValue
            removeStoriesTabIfNeeded(tabBarController)
            
            let albumsViewController = selectedNavigationController.viewControllers.first as! AlbumsCollectionViewController
            albumsViewController.albumManager = dataSourceBackup.albumManager!
            photobookDelegate = albumsViewController
        } else if let _ = dataSourceBackup.album as? InstagramAlbum {
            selectedNavigationController = tabBarController.viewControllers?[Tab.instagram.rawValue] as! UINavigationController
            tabBarController.selectedIndex = Tab.instagram.rawValue
            removeStoriesTabIfNeeded(tabBarController)
            
            let assetPickerViewController = selectedNavigationController.viewControllers.first as! AssetPickerCollectionViewController
            assetPickerViewController.album = dataSourceBackup.album!
            photobookDelegate = assetPickerViewController
        } else {
            selectedNavigationController = tabBarController.viewControllers?[Tab.stories.rawValue] as! UINavigationController
            tabBarController.selectedIndex = Tab.stories.rawValue
            
            let storiesViewController = selectedNavigationController.viewControllers.first as! StoriesViewController
            
            let assetPickerController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "AssetPickerCollectionViewController") as! AssetPickerCollectionViewController
            assetPickerController.delegate = storiesViewController
            selectedNavigationController.pushViewController(assetPickerController, animated: false)
            photobookDelegate = assetPickerController
            
            StoriesManager.shared.loadTopStories() { [weak welf = self] in
                let story = StoriesManager.shared.stories.first { $0.identifier == dataSourceBackup.album!.identifier }!
                assetPickerController.album = story
                assetPickerController.selectedAssetsManager = welf?.selectedAssetsManager
            }
        }
        
        return (selectedNavigationController, photobookDelegate)
    }
}
