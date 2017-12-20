//
//  AppDelegate.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 08/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit
import Photos

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let tabBarController = storyboard.instantiateViewController(withIdentifier: "TabBarController") as! UITabBarController
        
        if let albumViewController = (tabBarController.viewControllers?[1] as? UINavigationController)?.topViewController as? AlbumsCollectionViewController{
            albumViewController.albumManager = PhotosAlbumManager()
        }
        
        //Intro screen flow
        if PHPhotoLibrary.authorizationStatus() == .authorized {
            //if user denied access before, but enabled manually by going to the settings screen. Upon returning we don't want to display the intro screen anymore.
            IntroViewController.userHasDismissed = true
        }
        if IntroViewController.userHasDismissed {
            //set initial view controller to tab bar vc
            window?.rootViewController = tabBarController
        }
        
        ProductManager.shared.initialise(completion: { _ in })
        
        return true
    }
    
    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        // The application was woken up by a background task
        ProductManager.shared.loadUserPhotobook(completionHandler)
    }
}

