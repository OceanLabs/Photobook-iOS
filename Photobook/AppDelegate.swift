//
//  AppDelegate.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 08/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit
import Photos
import Fabric
import Crashlytics

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        Fabric.with([Crashlytics.self])
        
        //check if upload is in progress
        if ProductManager.shared.isUploading {
            //show receipt screen to prevent user from ordering another photobook
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let receiptViewController = storyboard.instantiateViewController(withIdentifier: "ReceiptTableViewController") as! ReceiptTableViewController
            receiptViewController.dismissClosure = { [weak welf = self] in
                let tabBarController = storyboard.instantiateViewController(withIdentifier: "TabBarController")
                welf?.window?.rootViewController = tabBarController
            }
            let navigationController = UINavigationController(navigationBarClass: PhotobookNavigationBar.self, toolbarClass: nil)
            navigationController.pushViewController(receiptViewController, animated: false)
            window?.rootViewController = navigationController
        }
        
        return true
    }
    
    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        // The application was woken up by a background task
        ProductManager.shared.loadUserPhotobook(completionHandler)
    }
}

