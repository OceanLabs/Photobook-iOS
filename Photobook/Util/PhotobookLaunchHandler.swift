//
//  AppLaunchHandler.swift
//  Photobook
//
//  Created by Julian Gruber on 19/03/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

@objc public class PhotobookLaunchHandler: NSObject {
    
    enum Tab: Int {
        case stories
        case browse
        case instagram
        case facebook
    }
    
    static func getInitialViewController() -> UIViewController {
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let tabBarController = storyboard.instantiateViewController(withIdentifier: "TabBarController") as! UITabBarController
        
        if IntroViewController.userHasDismissed && !OrderProcessingManager.shared.isProcessingOrder {
            configureTabBarController(tabBarController)
            return tabBarController
        }
        
        let rootNavigationController = UINavigationController(navigationBarClass: PhotobookNavigationBar.self, toolbarClass: nil)
        rootNavigationController.isNavigationBarHidden = true
        if #available(iOS 11.0, *) {
            rootNavigationController.navigationBar.prefersLargeTitles = false // large titles on nav vc containing other nav vcs causes issues
        }
        
        if !IntroViewController.userHasDismissed {
            let introViewController = storyboard.instantiateViewController(withIdentifier: "IntroViewController") as! IntroViewController
            introViewController.dismissClosure = {
                configureTabBarController(tabBarController)
                introViewController.proceedToTabBarController()
            }
            rootNavigationController.viewControllers = [introViewController]
            
        } else if OrderProcessingManager.shared.isProcessingOrder {
            //show receipt screen to prevent user from ordering another photobook
            let receiptViewController = storyboard.instantiateViewController(withIdentifier: "ReceiptTableViewController") as! ReceiptTableViewController
            receiptViewController.dismissClosure = {
                configureTabBarController(tabBarController)
                rootNavigationController.isNavigationBarHidden = true
                receiptViewController.proceedToTabBarController()
            }
            rootNavigationController.isNavigationBarHidden = false
            rootNavigationController.viewControllers = [receiptViewController]
        }
        
        return rootNavigationController
    }
    
    @objc public static func configureTabBarController(_ tabBarController: UITabBarController) {
        
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
