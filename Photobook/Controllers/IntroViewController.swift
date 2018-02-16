//
//  PhotoPermissionViewController.swift
//  Photobook
//
//  Created by Julian Gruber on 09/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit
import Photos
import OAuthSwift
import KeychainSwift

class IntroViewController: UIViewController {
    
    enum Tab: Int {
        case stories
        case browse
        case instagram
    }
    
    var userHasDismissed:Bool {
        get {
            return UserDefaults.standard.bool(forKey: "IntroViewController.userHasDismissed")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "IntroViewController.userHasDismissed")
            UserDefaults.standard.synchronize()
        }
    }
    
    @IBOutlet weak var ctaButton: UIButton!
    @IBOutlet weak var ctaContainerView: UIView!
    @IBOutlet weak var bgImageView: UIImageView!
    
    @IBOutlet weak var ctaVisibleConstraint: NSLayoutConstraint!
    @IBOutlet weak var ctaInvisibleConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        ctaVisibleConstraint.priority = .defaultLow
        ctaInvisibleConstraint.priority = .init(751)
        
        view.layoutIfNeeded()
        
        if PHPhotoLibrary.authorizationStatus() == .authorized {
            userHasDismissed = true
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if userHasDismissed {
            proceedToTabBarController()
        } else {
            showIntro()
        }

    }
    
    private func showIntro() {
        let animationDuration:Double = 0.7
        
        view.layoutIfNeeded()
        
        UIView.animateKeyframes(withDuration: animationDuration, delay: 1, options: .calculationModePaced, animations: {
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 1, animations: {
                self.ctaVisibleConstraint.priority = .init(751)
                self.ctaInvisibleConstraint.priority = .defaultLow
                
                self.view.layoutIfNeeded()
            })
        })
    }
    
    @IBAction func askForPhotoPermission(sender: UIButton) {
        let status = PHPhotoLibrary.authorizationStatus()
    
        switch status {
        case .notDetermined:
            ctaButton.isEnabled = false
            PHPhotoLibrary.requestAuthorization({ status in
                DispatchQueue.main.async {
                    self.ctaButton.isEnabled = true
                    
                    // We don't care about the outcome, the next screens will take care of showing the user an error screen if needed
                    self.userHasDismissed = true
                    self.proceedToTabBarController()
                }
            })
        default:
            userHasDismissed = true
            proceedToTabBarController()
        }
    }
    
    private func proceedToTabBarController() {
        performSegue(withIdentifier: "IntroDismiss", sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let segueIdentifier = segue.identifier else { return }
        
        if segueIdentifier == "IntroDismiss" {
            configureTabBarController(segue.destination as! UITabBarController)
        }
    }
    
    private func configureTabBarController(_ tabBarController: UITabBarController) {
        
        // Browse
        // Set the albumManager to the AlbumsCollectionViewController
        let albumViewController = (tabBarController.viewControllers?[Tab.browse.rawValue] as? UINavigationController)?.topViewController as? AlbumsCollectionViewController
        albumViewController?.albumManager = PhotosAlbumManager()
        
        // Instagram
        // Depending on whether we are logged in or not show the Instagram login screen or the asset picker
        if KeychainSwift().getData(keychainInstagramTokenKey) != nil { // FIXME check if we have a token
            let assetPicker = storyboard?.instantiateViewController(withIdentifier: "AssetPickerCollectionViewController") as! AssetPickerCollectionViewController
            assetPicker.album = InstagramAlbum()
            (tabBarController.viewControllers?[Tab.instagram.rawValue] as? UINavigationController)?.setViewControllers([assetPicker], animated: false)
        } else {
            let instagramLandingViewController = storyboard!.instantiateViewController(withIdentifier: "InstagramLandingViewController")
            (tabBarController.viewControllers?[Tab.instagram.rawValue] as? UINavigationController)?.setViewControllers([instagramLandingViewController], animated: false)
        }
        
        
        // Stories
        // If there are no stories, remove the stories tab
        StoriesManager.shared.loadTopStories()
        if StoriesManager.shared.stories.isEmpty {
            tabBarController.viewControllers?.remove(at: Tab.stories.rawValue)
        }
        
        // Load the products here, so that the user avoids a loading screen on PhotobookViewController
        ProductManager.shared.initialise(completion: nil)
        
    }

}
