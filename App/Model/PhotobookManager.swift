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
        
        #if STAGING
        PhotobookSDK.shared.shouldUseStaging = true
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
    
    var storiesTabAvailable = true
    func configureTabBarController(_ tabBarController: UITabBarController) {
        // Restore SelectedAssetManager from backup if present
        if let selectedAssetsManager = AssetDataSourceBackupManager.shared.restoreBackup() {
            self.selectedAssetsManager = selectedAssetsManager
        }
        
        // Assign the SelectedAssetManager to all album / pickers in the UITabBarController
        for viewController in tabBarController.viewControllers! {
            let rootNavigationController = viewController as! UINavigationController
            
            if var firstViewController = rootNavigationController.viewControllers.first as? Collectable {
                firstViewController.selectedAssetsManager = selectedAssetsManager
            }
        }

        // Remove stories tab if needed and push saved photo book if needed
        StoriesManager.shared.loadTopStories(completionHandler: { [weak welf = self] in
            if StoriesManager.shared.stories.isEmpty {
                tabBarController.viewControllers?.remove(at: Tab.stories.rawValue)
                welf?.storiesTabAvailable = false
            }
            
            welf?.restorePhotobookBackup(tabBarController)
        })
    }
    
    private func restorePhotobookBackup(_ tabBarController: UITabBarController) {
        if let photobookDelegate = photobookDelegate(tabBarController),
            let photobookViewController = PhotobookSDK.shared.photobookViewControllerFromBackup(embedInNavigation: false, navigatesToCheckout: false, delegate: photobookDelegate, completion: {
                (viewController, success) in
                
                guard success else {
                    if let tabBar = viewController.tabBarController?.tabBar {
                        tabBar.isHidden = false
                    }
                    
                    viewController.navigationController?.popViewController(animated: true)
                    return
                }
                
                let items = PhotobookSDK.shared.numberOfItemsInBasket()
                if items == 0 {
                    PhotobookSDK.shared.addCurrentProductToBasket()
                } else {
                    // Only allow one item in the basket
                    PhotobookSDK.shared.clearBasketOrder()
                    PhotobookSDK.shared.addCurrentProductToBasket(items: items)
                }
                
                // Push the checkout on completion
                if let checkoutViewController = PhotobookSDK.shared.checkoutViewController(embedInNavigation: false, dismissClosure: { viewController, success in
                    AssetDataSourceBackupManager.shared.deleteBackup()
                    
                    viewController.navigationController?.popToRootViewController(animated: true)
                    if success {
                        NotificationCenter.default.post(name: SelectedAssetsManager.notificationNamePhotobookComplete, object: nil)
                    }
                }) {
                    let selectedNavigationController = tabBarController.viewControllers?.first as! UINavigationController
                    selectedNavigationController.pushViewController(checkoutViewController, animated: true)
                }
        }) {
            let selectedNavigationController = tabBarController.viewControllers?.first as! UINavigationController
            selectedNavigationController.pushViewController(photobookViewController, animated: false)
        }
    }
    
    private func photobookDelegate(_ tabBarController: UITabBarController) -> PhotobookDelegate? {
        var photobookDelegate: PhotobookDelegate?
        
        for viewController in tabBarController.viewControllers! {
            guard let rootNavigationController = viewController as? UINavigationController,
                  let firstViewController = rootNavigationController.viewControllers.first as? Collectable else { continue }

            photobookDelegate = firstViewController as? PhotobookDelegate
            break
        }
        
        return photobookDelegate
    }
    
    func photobook(from presenter: UIViewController, assets: [PhotobookAsset], delegate: PhotobookDelegate) {
        if UserDefaults.standard.bool(forKey: hasShownTutorialKey) {
            if let viewController = photobookViewController(from: presenter, withAssets: assets, delegate: delegate) {
                presenter.navigationController?.pushViewController(viewController, animated: true)
            }
        } else {
            guard let photobookViewController = photobookViewController(from: presenter, withAssets: assets, delegate: delegate) else { return }
            
            let completion = {
                UserDefaults.standard.set(true, forKey: hasShownTutorialKey)
                
                let tutorialViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "TutorialViewController") as! TutorialViewController
                tutorialViewController.completionClosure = { (viewController) in
                    presenter.dismiss(animated: true, completion: nil)
                }
                presenter.present(tutorialViewController, animated: true)
            }
            
            CATransaction.begin()
            CATransaction.setCompletionBlock(completion)
            presenter.navigationController?.pushViewController(photobookViewController, animated: true)
            CATransaction.commit()
        }
    }
    
    private func photobookViewController(from presenter: UIViewController, withAssets assets: [PhotobookAsset], delegate: PhotobookDelegate) -> UIViewController? {
        
        let photobookViewController = PhotobookSDK.shared.photobookViewController(with: assets, embedInNavigation: false, navigatesToCheckout: false, delegate: delegate) {
            (viewController, success) in
            
            guard success else {
                if let tabBar = viewController.tabBarController?.tabBar {
                    tabBar.isHidden = false
                }
                
                viewController.navigationController?.popViewController(animated: true)
                return
            }
            
            let items = PhotobookSDK.shared.numberOfItemsInBasket()
            if items == 0 {
                PhotobookSDK.shared.addCurrentProductToBasket()
            } else {
                // Only allow one item in the basket
                PhotobookSDK.shared.clearBasketOrder()
                PhotobookSDK.shared.addCurrentProductToBasket(items: items)
            }
            
            // Photobook completion
            if let checkoutViewController = PhotobookSDK.shared.checkoutViewController(embedInNavigation: false, dismissClosure: {
                (viewController, success) in
                AssetDataSourceBackupManager.shared.deleteBackup()
                
                presenter.navigationController?.popToRootViewController(animated: true)
                if success {
                    NotificationCenter.default.post(name: SelectedAssetsManager.notificationNamePhotobookComplete, object: nil)
                }
            }) {
                presenter.navigationController?.pushViewController(checkoutViewController, animated: true)
            }
        }
        return photobookViewController
    }
}
