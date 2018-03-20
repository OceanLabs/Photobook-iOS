//
//  AppLaunchHandler.swift
//  Photobook
//
//  Created by Julian Gruber on 19/03/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

class AppLaunchHandler {
    
    enum Tab: Int {
        case stories
        case browse
        case instagram
        case facebook
    }
    
    static func enterApp(window: UIWindow) {
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let tabBarController = storyboard.instantiateViewController(withIdentifier: "TabBarController") as! UITabBarController
        let goToTabBarControllerClosure = {
            configureTabBarController(tabBarController)
            window.rootViewController = tabBarController
        }
        
        if IntroViewController.userHasDismissed && !OrderProcessingManager.shared.isProcessingOrder {
            goToTabBarControllerClosure()
            return
        }
        
        if !IntroViewController.userHasDismissed {
            let introViewController = storyboard.instantiateViewController(withIdentifier: "IntroViewController") as! IntroViewController
            introViewController.dismissClosure = goToTabBarControllerClosure
            window.rootViewController = introViewController
            
            return
        }
        
        if OrderProcessingManager.shared.isProcessingOrder {
            //show receipt screen to prevent user from ordering another photobook
            let receiptViewController = storyboard.instantiateViewController(withIdentifier: "ReceiptTableViewController") as! ReceiptTableViewController
            receiptViewController.dismissClosure = goToTabBarControllerClosure
            
            let navigationController = UINavigationController(navigationBarClass: PhotobookNavigationBar.self, toolbarClass: nil)
            navigationController.pushViewController(receiptViewController, animated: false)
            window.rootViewController = navigationController
            
            return
        }
        
    }
    
    static func proceedToTabBarController() {
        
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
