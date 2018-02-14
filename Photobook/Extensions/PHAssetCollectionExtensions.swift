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
        DispatchQueue.global(qos: .background).async {
            let fetchOptions = PHFetchOptions()
            fetchOptions.fetchLimit = 1
            fetchOptions.wantsIncrementalChangeDetails = false
            fetchOptions.includeHiddenAssets = false
            fetchOptions.includeAllBurstAssets = false
            fetchOptions.sortDescriptors = [ NSSortDescriptor(key: "creationDate", ascending: useFirstImageInCollection) ]
            
            guard let coverAsset = PHAsset.fetchAssets(in: self, options: fetchOptions).firstObject else {
                DispatchQueue.main.async {
                    completionHandler(nil, nil) //TODO: return an error
                }
                return
            }
            
            DispatchQueue.main.async {
                completionHandler(PhotosAsset(coverAsset, albumIdentifier: self.localIdentifier), nil)
            }
        }
    }
    
}
