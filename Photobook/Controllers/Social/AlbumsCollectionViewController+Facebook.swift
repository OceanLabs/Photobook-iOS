//
//  AlbumsCollectionViewController+Facebook.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 02/03/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import FBSDKLoginKit

extension AlbumsCollectionViewController {
    
    static func facebookAlbumsCollectionViewController() -> AlbumsCollectionViewController {
        let albumViewController = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "AlbumsCollectionViewController") as! AlbumsCollectionViewController
        albumViewController.albumManager = FacebookAlbumManager()
        albumViewController.navigationItem.rightBarButtonItem = UIBarButtonItem(title: NSLocalizedString("Social/Logout", value: "Log Out", comment: "Button title for loggin out of social accounts, eg Facebook, Instagram"), style: .plain, target: albumViewController, action: #selector(facebookLogout))
        return albumViewController
    }
    
    @objc private func facebookLogout() {
        let serviceName = "Facebook"
        let alertController = UIAlertController(title: NSLocalizedString("Social/LogoutConfirmationAlertTitle", value: "Log Out", comment: "Alert title asking the user to log out of social service eg Instagram/Facebook"), message: NSLocalizedString("Social/LogoutConfirmationAlertMessage", value: "Are you sure you want to log out of \(serviceName)?", comment: "Alert message asking the user to log out of social service eg Instagram/Facebook"), preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Alert/Yes", value: "Yes", comment: "Affirmative button title for alert asking the user confirmation for an action"), style: .default, handler: { _ in
            FBSDKLoginManager().logOut()
            
            guard let viewController = self.storyboard?.instantiateViewController(withIdentifier: "FacebookLandingViewController") else { return }
            self.navigationController?.setViewControllers([viewController, self], animated: false)
            self.navigationController?.popViewController(animated: true)
        }))
        
        alertController.addAction(UIAlertAction(title: CommonLocalizedStrings.cancel, style: .cancel, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
}
