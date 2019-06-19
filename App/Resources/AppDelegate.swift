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
import Photobook

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        Fabric.with([Crashlytics.self])
        PhotobookManager.shared.setup()
        
        let result = FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
        
        if !PhotobookApp.isRunningUnitTests() {
            window?.rootViewController = PhotobookManager.shared.rootViewControllerForCurrentState()
            Analytics.shared.optInToRemoteAnalytics = true
        }
        
        return result
    }
    
    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        // The application was woken up by a background task
        PhotobookSDK.shared.loadProcessingOrderAfterBackgroundRequest(completionHandler)
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        let kiteHandled = PhotobookSDK.shared.handleUrlCallBack(with: url)
        return kiteHandled || FBSDKApplicationDelegate.sharedInstance().application(_: app, open: url, options: options)
    }
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
              let url = userActivity.webpageURL else { return false }
        return PhotobookSDK.shared.handleUrlCallBack(with: url)
    }
}

class PhotobookApp {
    static func isRunningUnitTests() -> Bool {
        return ProcessInfo.processInfo.environment["TESTS_RUNNING"] != nil
    }
}
