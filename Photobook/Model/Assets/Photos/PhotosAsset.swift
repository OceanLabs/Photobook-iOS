//
//  PhotosAsset.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 08/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit
import Photos

class PhotosAsset: Asset {
    private var photosAsset: PHAsset
    
    var width: CGFloat { return CGFloat(photosAsset.pixelWidth) }
    var height: CGFloat { return CGFloat(photosAsset.pixelHeight) }
    var isLandscape: Bool = false
    
    init(_ asset: PHAsset) {
        photosAsset = asset
    }
}
