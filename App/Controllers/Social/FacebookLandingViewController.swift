//
//  FacebookLandingViewController.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 01/03/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit
import FBSDKLoginKit

class FacebookLandingViewController: UIViewController {
    
    @IBOutlet weak var facebookLogoCenterYConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // If we are logged in show the Facebook album picker
        if FBSDKAccessToken.current() != nil {
            
            // Hide all views because this screen will be shown for a split second
            for view in view.subviews {
                view.isHidden = true
            }
            
            let facebookAssetPicker = AlbumsCollectionViewController.facebookAlbumsCollectionViewController()
            facebookAssetPicker.assetPickerDelegate = facebookAssetPicker
            
            // Animated: needs to be true or else it won't show the title
            navigationController?.setViewControllers([facebookAssetPicker], animated: true)
            
            return
        } 
        
        if let navigationController = navigationController {
            facebookLogoCenterYConstraint.constant = -(navigationController.navigationBar.frame.height / 2.0)
        }
    }
    
    @IBAction func facebookSignInTapped(_ sender: UIButton) {
        FBSDKLoginManager().logIn(withReadPermissions: ["public_profile", "user_photos"], from: self, handler: { [weak welf = self] result, error in
            if let error = error {
                welf?.present(UIAlertController(errorMessage: ErrorMessage(error)), animated: true, completion: nil)
                return
            } else if let result = result, !result.isCancelled {
                let facebookAlbumsCollectionViewController = AlbumsCollectionViewController.facebookAlbumsCollectionViewController()
                facebookAlbumsCollectionViewController.assetPickerDelegate = facebookAlbumsCollectionViewController
                welf?.navigationController?.setViewControllers([facebookAlbumsCollectionViewController], animated: false)
            }
        })
    }
    
    
}
