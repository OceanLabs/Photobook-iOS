//
//  PHAssetCollectionExtensions.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 17/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import Photos

extension PHAssetCollection {
    
    func coverImage(size: CGSize, completionHandler: @escaping (UIImage?, Error?) -> Void) {
        DispatchQueue.global(qos: .background).async {
            let fetchOptions = PHFetchOptions()
            fetchOptions.fetchLimit = 1
            fetchOptions.wantsIncrementalChangeDetails = false
            fetchOptions.includeHiddenAssets = false
            fetchOptions.includeAllBurstAssets = false
            fetchOptions.sortDescriptors = [ NSSortDescriptor(key: "creationDate", ascending: false) ]
            
            guard let coverAsset = PHAsset.fetchAssets(in: self, options: fetchOptions).firstObject else{
                DispatchQueue.main.async {
                    completionHandler(nil, nil) //TODO: return an error
                }
                return
            }
            
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isNetworkAccessAllowed = true
            
            let imageSize = CGSize(width: size.width * UIScreen.main.usableScreenScale(), height: size.height * UIScreen.main.usableScreenScale())
            PHImageManager.default().requestImage(for: coverAsset, targetSize: imageSize, contentMode: .aspectFill, options: options, resultHandler: { (image, _) in
                guard let image = image else {
                    DispatchQueue.main.async {
                        completionHandler(nil, nil) //TODO: return an error
                    }
                    return
                }
                
                DispatchQueue.main.async {
                    completionHandler(image, nil)
                }
            })
        }
    }
    
}
