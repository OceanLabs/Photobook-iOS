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
    
    var assetType: String {
        return NSStringFromClass(PhotosAsset.self)
    }
    
    var photosAsset: PHAsset! {
        didSet {
            identifier = photosAsset.localIdentifier
        }
    }
    var identifier: String! {
        didSet {
            if photosAsset == nil || photosAsset.localIdentifier != identifier,
               let asset = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: PHFetchOptions()).firstObject {
                    photosAsset = asset
            }
        }
    }
    
    var size: CGSize { return CGSize(width: photosAsset.pixelWidth, height: photosAsset.pixelHeight) }
    var isLandscape: Bool {
        return self.size.width > self.size.height
    }
    var remoteUrl: String?
    
    convenience init(_ asset: PHAsset) {
        self.init()
        photosAsset = asset
        identifier = photosAsset.localIdentifier
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
