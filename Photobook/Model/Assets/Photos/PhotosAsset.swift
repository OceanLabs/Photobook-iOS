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
    
    var photosAsset: PHAsset
    var photosAssetCollection: PHAssetCollection
    
    var identifier: String{
        return photosAsset.localIdentifier
    }
    
    var albumIdentifier: String {
        return photosAssetCollection.localIdentifier
    }
    
    init(_ asset: PHAsset, collection:PHAssetCollection){
        photosAsset = asset
        photosAssetCollection = collection
    }
    
    func uneditedImage(size: CGSize, progressHandler: ((Int64, Int64) -> Void)?, completionHandler: @escaping (UIImage?, Error?) -> Void) {
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.isNetworkAccessAllowed = true
        
        let imageSize = CGSize(width: size.width * UIScreen.main.usableScreenScale(), height: size.height * UIScreen.main.usableScreenScale())
        PHImageManager.default().requestImage(for: photosAsset, targetSize: imageSize, contentMode: .aspectFill, options: options) { (image, _) in
            completionHandler(image, nil)
        }
    }
    
}
