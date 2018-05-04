//
//  Helpers.swift
//  AssetMocks
//
//  Created by Jaime Landazuri on 03/05/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import Foundation
import Photos
@testable import Photobook

class TestPHAsset: PHAsset {
    
    var localIdentifierStub: String?
    var widthStub: Int!
    var heightStub: Int!
    var mediaTypeStub: PHAssetMediaType? = .image
    var dateStub: Date?
    
    override var pixelWidth: Int { return widthStub ?? 0 }
    override var pixelHeight: Int { return heightStub ?? 0 }
    override var creationDate: Date? { return dateStub }
    override var mediaType: PHAssetMediaType { return mediaTypeStub! }
    override var localIdentifier: String { return localIdentifierStub ?? "" }
}

class TestFetchResult: PHFetchResult<PHAsset> {
    
    var phAssetsStub: [PHAsset]!
    var bool = ObjCBool(false)
    
    override func enumerateObjects(_ block: @escaping (PHAsset, Int, UnsafeMutablePointer<ObjCBool>) -> Void) {
        for i in 0 ..< phAssetsStub.count {
            block(phAssetsStub[i], i, &bool)
        }
    }
}

class TestFetchResultChangeDetails: PHFetchResultChangeDetails<PHAsset> {
    var phInsertedAssetsStub: [PHAsset]!
    var phRemovedAssetsStub: [PHAsset]!

    override var insertedObjects: [PHAsset] { return phInsertedAssetsStub }
    override var removedObjects: [PHAsset] { return phRemovedAssetsStub }
}

class TestChangeManager: ChangeManager {
    var phInsertedAssetsStub: [PHAsset]!
    var phRemovedAssetsStub: [PHAsset]!

    func details(for fetchResult: PHFetchResult<PHAsset>) -> PHFetchResultChangeDetails<PHAsset>? {
        let testFetchResultChangeDetails = TestFetchResultChangeDetails()
        testFetchResultChangeDetails.phInsertedAssetsStub = phInsertedAssetsStub
        testFetchResultChangeDetails.phRemovedAssetsStub = phRemovedAssetsStub
        return testFetchResultChangeDetails
    }
}

// Conforms to the AssetManager protocol to get around dependencies on static methods for PHAsset
class TestAssetManager: AssetManager {
    
    var phAssetsStub: [PHAsset]?
    
    func fetchAssets(withLocalIdentifiers identifiers: [String], options: PHFetchOptions?) -> PHAsset? {
        return phAssetsStub?.first
    }
    
    func fetchAssets(in: AssetCollection, options: PHFetchOptions) -> PHFetchResult<PHAsset> {
        let fetchResult = TestFetchResult()
        fetchResult.phAssetsStub = phAssetsStub
        return fetchResult
    }
}

class TestImageManager: PHImageManager {
    
    var imageData: Data!
    var dataUti: String!
    
    override func requestImage(for asset: PHAsset, targetSize: CGSize, contentMode: PHImageContentMode, options: PHImageRequestOptions?, resultHandler: @escaping (UIImage?, [AnyHashable : Any]?) -> Void) -> PHImageRequestID {
        
        let image = UIImage(color: .black, size: targetSize)
        
        resultHandler(image, nil)
        
        return 0
    }
    
    override func requestImageData(for asset: PHAsset, options: PHImageRequestOptions?, resultHandler: @escaping (Data?, String?, UIImageOrientation, [AnyHashable : Any]?) -> Void) -> PHImageRequestID {
        
        resultHandler(imageData, dataUti, .up, nil)
        
        return 0
    }
}

class TestWebImageManager: WebImageManager {
    
    var url: URL?
    var imageDataStub: Data?
    var imageStub: UIImage?
    
    func loadImage(with url: URL, completion: @escaping (UIImage?, Data?, Error?) -> Void) {
        self.url = url
        completion(imageStub, imageDataStub, nil)
    }
}

class TestAssetCollection: AssetCollection {
    
    var localizedTitle: String? = nil
    var localIdentifier: String = "localIdentifier"
    var estimatedAssetCount: Int = 0
    
    func coverAsset(useFirstImageInCollection: Bool, completionHandler: @escaping (Asset?, Error?) -> Void) {
        completionHandler(TestPhotosAsset(), nil)
    }
}

class TestFacebookApiManager: FacebookApiManager {

    var result: Any?
    var error: LocalizedError?
    
    func request(withGraphPath path: String, parameters: [String: Any]?, completion: @escaping (Any?, Error?) -> Void) {
        completion(result, error)
    }
}
