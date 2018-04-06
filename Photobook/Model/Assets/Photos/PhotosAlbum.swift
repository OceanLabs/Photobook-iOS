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
    var hasMoreAssetsToLoad = false

    init(_ assetCollection: PHAssetCollection) {
        self.assetCollection = assetCollection
    }
    
    /// Returns the estimated number of assets for this album, which might not be available without calling loadAssets. It might differ from the actual number of assets. NSNotFound if not available.
    var numberOfAssets: Int{
        return !assets.isEmpty ? assets.count : assetCollection.estimatedAssetCount
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
    
    func loadNextBatchOfAssets(completionHandler: ((Error?) -> Void)?) {}
    
}

extension PhotosAlbum: PickerAnalytics {
    var selectingPhotosScreenName: Analytics.ScreenName { return .picker }
    var addingMorePhotosScreenName: Analytics.ScreenName { return .pickerAddingMorePhotos }
}
