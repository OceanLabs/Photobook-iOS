//
//  AssetPickerCollectionViewController+Instagram.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 16/02/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import OAuthSwift
import KeychainSwift

extension AssetPickerCollectionViewController {
    
    static func instagramAssetPicker() -> AssetPickerCollectionViewController{
        let assetPicker = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "AssetPickerCollectionViewController") as! AssetPickerCollectionViewController
        assetPicker.album = InstagramAlbum(authenticationHandler: assetPicker)
        assetPicker.selectedAssetsManager = SelectedAssetsManager()
        assetPicker.navigationItem.rightBarButtonItem = UIBarButtonItem(title: NSLocalizedString("Social/Logout", value: "Log Out", comment: "Button title for loggin out of social accounts, eg Facebook, Instagram"), style: .plain, target: assetPicker, action: #selector(instagramLogout))
        
        return assetPicker
    }
    
    @objc private func instagramLogout() {
        let serviceName = "Instagram"
        let alertController = UIAlertController(title: NSLocalizedString("Social/LogoutConfirmationAlertTitle", value: "Log Out", comment: "Alert title asking the user to log out of social service eg Instagram/Facebook"), message: NSLocalizedString("Social/LogoutConfirmationAlertMessage", value: "Are you sure you want to log out of \(serviceName)?", comment: "Alert message asking the user to log out of social service eg Instagram/Facebook"), preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Alert/Yes", value: "Yes", comment: "Affirmative button title for alert asking the user confirmation for an action"), style: .default, handler: { _ in
            self.performInstagramLogout()
        }))
        
        alertController.addAction(UIAlertAction(title: CommonLocalizedStrings.cancel, style: .cancel, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
    @objc func performInstagramLogout() {
        KeychainSwift().delete(OAuth2Swift.Constants.keychainInstagramTokenKey)
        
        guard let viewController = self.storyboard?.instantiateViewController(withIdentifier: "InstagramLandingViewController") else { return }
        self.navigationController?.setViewControllers([viewController, self], animated: false)
        self.navigationController?.popViewController(animated: true)
    }
    
}

extension AssetPickerCollectionViewController: OAuthSwiftURLHandlerType {
    
    func handle(_ url: URL) {
        navigationController?.pushViewController(storyboard!.instantiateViewController(withIdentifier: "InstagramLandingViewController"), animated: true)
    }
    
}
