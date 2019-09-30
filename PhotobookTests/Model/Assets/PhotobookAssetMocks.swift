//
//  ManagerMocks.swift
//  PhotobookTests
//
//  Created by Jaime Landazuri on 06/11/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit
import Photos
@testable import Photobook

// Conforms to the AssetManager protocol to get around dependencies on static methods for PHAsset
class AssetManagerMock: AssetManager {
    
    var phAssetsStub: [PHAssetMock]?
    
    func fetchAsset(withLocalIdentifier identifier: String, options: PHFetchOptions?) -> PHAsset? {
        return phAssetsStub?.first
    }
    
    func fetchAssets(in assetCollection: PHAssetCollection, options: PHFetchOptions) -> PHFetchResult<PHAsset> {
        guard let assets = phAssetsStub, let assetCollection = assetCollection as? PHAssetCollectionMock else { return AssetFetchResultMock() }
        let fetchResult = AssetFetchResultMock()
        fetchResult.phAssetsStub = assets.filter { $0.listIdentifier == assetCollection.localIdentifier }
        return fetchResult
    }
}

class WebImageManagerMock: WebImageManager {
    
    var url: URL?
    var imageDataStub: Data?
    var imageStub: UIImage?
    
    func loadImage(with url: URL, completion: @escaping (UIImage?, Data?, Error?) -> Void) {
        self.url = url
        completion(imageStub, imageDataStub, nil)
    }
}
