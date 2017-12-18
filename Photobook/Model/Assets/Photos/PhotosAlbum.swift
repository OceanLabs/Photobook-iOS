//
//  PhotosAlbum.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 08/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit
import Photos

class PhotosAlbum: Album {
    
    private let assetCollection: PHAssetCollection
    var assets = [Asset]()

    init(_ assetCollection: PHAssetCollection) {
        self.assetCollection = assetCollection
    }
    
    var numberOfAssets: Int{
        return assets.count > 0 ? assets.count : assetCollection.estimatedAssetCount
    }
    
    var localizedName: String?{
        return assetCollection.localizedTitle
    }
    
    var identifier: String{
        return assetCollection.localIdentifier
    }
    
    func loadAssets(completionHandler: ((Error?) -> Void)?) {
        DispatchQueue.global(qos: .background).async { [weak welf = self] in
            welf?.loadAssetsFromPhotoLibrary()
            DispatchQueue.main.async {
                completionHandler?(nil)
            }
        }
    }
    
    func loadAssetsFromPhotoLibrary() {
        let fetchOptions = PHFetchOptions()
        fetchOptions.wantsIncrementalChangeDetails = false
        fetchOptions.includeHiddenAssets = false
        fetchOptions.includeAllBurstAssets = false
        fetchOptions.sortDescriptors = [ NSSortDescriptor(key: "creationDate", ascending: false) ]
        let fetchedAssets = PHAsset.fetchAssets(in: assetCollection, options: fetchOptions)
        fetchedAssets.enumerateObjects({ (asset, _, _) in
            self.assets.append(PhotosAsset(asset, collection: self.assetCollection))
        })
    }
    
    func coverImage(size: CGSize, completionHandler: @escaping (UIImage?, Error?) -> Void) {
        assetCollection.coverImage(size: size, completionHandler: completionHandler)
    }
    
}
