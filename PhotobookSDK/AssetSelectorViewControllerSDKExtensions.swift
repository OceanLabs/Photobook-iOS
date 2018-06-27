//
//  AssetSelectorViewControllerSDKExtensions.swift
//  PhotobookSDK
//
//  Created by Konstadinos Karayannis on 25/06/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

extension AssetSelectorViewController {
    
    func modalImagePickerViewController() -> (PhotobookAssetPicker & UIViewController)? {
        return assetPickerViewController as? PhotobookAssetPicker & UIViewController
    }
    
}
