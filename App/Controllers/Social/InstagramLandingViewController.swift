//
//  InstagramLandingViewController.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 20/02/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit
import KeychainSwift
import OAuthSwift

class InstagramLandingViewController: UIViewController {

    @IBOutlet weak var instagramLogoCenterYConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // If we are logged in show the Instagram asset picker
        if KeychainSwift().getData(InstagramClient.Constants.keychainInstagramTokenKey) != nil {
            // Hide all views because this screen will be shown for a split second
            for view in view.subviews {
                view.isHidden = true
            }
            
            let instagramAssetPicker = AssetPickerCollectionViewController.instagramAssetPicker()
            instagramAssetPicker.delegate = instagramAssetPicker
            
            // Animated: needs to be true or else it won't show the title
            navigationController?.setViewControllers([instagramAssetPicker], animated: true)
            return
        }

        if let navigationController = navigationController {
            instagramLogoCenterYConstraint.constant = -(navigationController.navigationBar.frame.height / 2.0)
        }
    }

}
