//
//  PHAssetCollectionExtensions.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 17/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import Photos

extension PHAssetCollection {
    
    func coverAsset(useFirstImageInCollection: Bool, completionHandler: @escaping (Asset?, Error?) -> Void) {
        DispatchQueue.global(qos: .default).async {
            let fetchOptions = PHFetchOptions()
            fetchOptions.wantsIncrementalChangeDetails = false
            fetchOptions.includeHiddenAssets = false
            fetchOptions.includeAllBurstAssets = false
            fetchOptions.sortDescriptors = [ NSSortDescriptor(key: "creationDate", ascending: useFirstImageInCollection) ]
            
            var coverAsset: PhotosAsset? = nil
            let fetchedAssets = PHAsset.fetchAssets(in: self, options: fetchOptions)
            fetchedAssets.enumerateObjects({ asset, _, stop in
                if asset.mediaType == .image {
                    coverAsset = PhotosAsset(asset, albumIdentifier: self.localIdentifier)
                    stop.initialize(to: true)
                }
            })
            
            DispatchQueue.main.async {
                completionHandler(coverAsset, nil)
            }
        }
    }
    
}
