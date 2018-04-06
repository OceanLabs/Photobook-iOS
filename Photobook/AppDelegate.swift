//
//  AppDelegate.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 08/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit
import Fabric
import Crashlytics
import FBSDKCoreKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        Fabric.with([Crashlytics.self])
        
        #if TEST_ENVIRONMENT
        PhotobookLaunchHandler.environment = .test
        #endif
        
        window?.rootViewController = PhotobookManager.rootViewControllerForCurrentState()
        
        // Force the static var to initialize so it doesn't miss any notifications
        _ = Analytics.shared
        
        return FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        // The application was woken up by a background task
        ProductManager.shared.loadUserPhotobook(completionHandler)
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        return FBSDKApplicationDelegate.sharedInstance().application(_: app, open: url, options: options)
    }
}

