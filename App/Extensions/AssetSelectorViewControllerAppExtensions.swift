//
//  AssetSelectorViewControllerExtensions.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 25/06/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

extension AssetSelectorViewController {
    
    func modalImagePickerViewController() -> (PhotobookAssetPicker & UIViewController)? {
        let modalAlbumsCollectionViewController = mainStoryboard.instantiateViewController(withIdentifier: "ModalAlbumsCollectionViewController") as! ModalAlbumsCollectionViewController
        modalAlbumsCollectionViewController.album = album
        modalAlbumsCollectionViewController.albumManager = albumManager
        modalAlbumsCollectionViewController.addingDelegate = self
        return modalAlbumsCollectionViewController
    }
    
}
