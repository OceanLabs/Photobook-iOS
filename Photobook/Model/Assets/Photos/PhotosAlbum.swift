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
    
    let assetCollection: PHAssetCollection
    var assets = [Asset]()
    var fetchedAssets: PHFetchResult<PHAsset>?

    init(_ assetCollection: PHAssetCollection) {
        self.assetCollection = assetCollection
    }
    
    var numberOfAssets: Int{
        return !assets.isEmpty ? assets.count : assetCollection.estimatedAssetCount
    }
    
    var localizedName: String?{
        return assetCollection.localizedTitle
    }
    
    var identifier: String{
        return assetCollection.localIdentifier
    }
    
    var requiresExclusivePicking: Bool {
        return false
    }
    
    func loadAssets(completionHandler: ((ErrorMessage?) -> Void)?) {
        DispatchQueue.global(qos: .background).async { [weak welf = self] in
            welf?.loadAssetsFromPhotoLibrary()
            DispatchQueue.main.async {
                completionHandler?(nil)
            }
        }
    }
    
    func loadAssetsFromPhotoLibrary() {
        let fetchOptions = PHFetchOptions()
        fetchOptions.wantsIncrementalChangeDetails = true
        fetchOptions.includeHiddenAssets = false
        fetchOptions.includeAllBurstAssets = false
        fetchOptions.sortDescriptors = [ NSSortDescriptor(key: "creationDate", ascending: false) ]
        let fetchedAssets = PHAsset.fetchAssets(in: assetCollection, options: fetchOptions)
        var assets = [Asset]()
        fetchedAssets.enumerateObjects({ (asset, _, _) in
            assets.append(PhotosAsset(asset, albumIdentifier: self.identifier))
        })
        
        self.assets = assets
        self.fetchedAssets = fetchedAssets
    }
    
    func coverAsset(completionHandler: @escaping (Asset?, Error?) -> Void) {
        assetCollection.coverAsset(useFirstImageInCollection: false, completionHandler: completionHandler)
    }
    
}
