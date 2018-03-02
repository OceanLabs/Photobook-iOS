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
        
        if let navigationController = navigationController {
            facebookLogoCenterYConstraint.constant = -(navigationController.navigationBar.frame.height / 2.0)
        }
    }
    
    @IBAction func facebookSignInTapped(_ sender: UIButton) {
        FBSDKLoginManager().logIn(withReadPermissions: ["public_profile", "user_photos"], from: self, handler: { [weak welf = self] result, error in
            if let errorMessage = ErrorMessage(error) {
                welf?.present(UIAlertController(errorMessage: errorMessage), animated: true, completion: nil)
                return
            } else if let result = result, !result.isCancelled {
                let facebookAlbumsCollectionViewController = AlbumsCollectionViewController.facebookAlbumsCollectionViewController()
                facebookAlbumsCollectionViewController.assetPickerDelegate = facebookAlbumsCollectionViewController
                welf?.navigationController?.setViewControllers([facebookAlbumsCollectionViewController], animated: false)
            }
        })
    }
    
    
}
