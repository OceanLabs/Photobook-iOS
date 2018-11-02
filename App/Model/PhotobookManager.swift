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
        PhotobookSDK.shared.applePayMerchantId = Configuration.applePayPayToString
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
            let receiptViewController = PhotobookSDK.shared.receiptViewController(embedInNavigation: true) { [weak welf = self] viewController in
                guard let stelf = welf else { return }
                let tabBarController = mainStoryboard.instantiateViewController(withIdentifier: "TabBarController") as! UITabBarController
                stelf.configureTabBarController(tabBarController)
                let dismissSegue = IntroDismissSegue(identifier: "ReceiptDismiss", source: viewController, destination: tabBarController)
                dismissSegue.perform()
                
                NotificationCenter.default.post(name: SelectedAssetsManager.notificationNamePhotobookComplete, object: nil)
            }
            
            rootNavigationController.viewControllers = receiptViewController != nil ? [receiptViewController!] : [UIViewController()]
        }
        
        return rootNavigationController
    }
    
    func configureTabBarController(_ tabBarController: UITabBarController) {
        
        // Attempt to restore photobook backup
        let browseNavigationViewController = tabBarController.viewControllers?[Tab.browse.rawValue] as? UINavigationController
        let assetPickerViewController = browseNavigationViewController?.viewControllers.first as? AlbumsCollectionViewController
        if let photobookViewController = PhotobookSDK.shared.photobookViewControllerFromBackup(embedInNavigation: false, delegate: assetPickerViewController, completion: {
            let items = Checkout.shared.numberOfItemsInBasket()
            if items == 0 {
                Checkout.shared.addCurrentProductToBasket()
            } else {
                // Only allow one item in the basket
                Checkout.shared.clearBasketOrder()
                Checkout.shared.addCurrentProductToBasket(items: items)
            }
            
            // Push the checkout on completion
            if let checkoutViewController = PhotobookSDK.shared.checkoutViewController(embedInNavigation: false, delegate: assetPickerViewController) {
                browseNavigationViewController?.pushViewController(checkoutViewController, animated: true)
            }
        }) {
            browseNavigationViewController?.pushViewController(photobookViewController, animated: false)
            tabBarController.selectedIndex = Tab.browse.rawValue
        }

        // Stories
        // If there are no stories, remove the stories tab
        StoriesManager.shared.loadTopStories(completionHandler: {
            if StoriesManager.shared.stories.isEmpty {
                tabBarController.viewControllers?.remove(at: Tab.stories.rawValue)
            }
        })
    }
}
