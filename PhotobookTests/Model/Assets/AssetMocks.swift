//
//  Helpers.swift
//  AssetMocks
//
//  Created by Jaime Landazuri on 03/05/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import Foundation
import Photos
import OAuthSwift
@testable import Photobook

// MARK: - Photo Library object mocks
class TestPHAsset: PHAsset {
    
    var localIdentifierStub: String?
    var listIdentifier: String?
    var widthStub: Int!
    var heightStub: Int!
    var mediaTypeStub: PHAssetMediaType? = .image
    var dateStub: Date?
    
    override var pixelWidth: Int { return widthStub ?? 0 }
    override var pixelHeight: Int { return heightStub ?? 0 }
    override var creationDate: Date? { return dateStub }
    override var mediaType: PHAssetMediaType { return mediaTypeStub! }
    override var localIdentifier: String { return localIdentifierStub ?? "id" }
}

class TestPHAssetCollection: PHAssetCollection {
    var localIdentifierStub: String? = "assetCollection"
    var listIdentifier: String?
    override var localIdentifier: String { return localIdentifierStub ?? "id" }
}

class TestPHCollectionList: PHCollectionList {
    var localIdentifierStub: String? = "collectionList"
    var localizedTitleStub: String?
    var startDateStub: Date?
    var endDateStub: Date?
    
    override var localIdentifier: String { return localIdentifierStub ?? "id" }
    override var localizedTitle: String? { return localizedTitleStub ?? "collectionList" }
    override var startDate: Date? { return startDateStub }
    override var endDate: Date? { return endDateStub }
}

// MARK: - Photo Library fetch result mocks
class TestAssetFetchResult: PHFetchResult<PHAsset> {
    var phAssetsStub: [PHAsset]!
    var bool = ObjCBool(false)
    
    override func enumerateObjects(_ block: @escaping (PHAsset, Int, UnsafeMutablePointer<ObjCBool>) -> Void) {
        for i in 0 ..< phAssetsStub.count {
            block(phAssetsStub[i], i, &bool)
        }
    }
    override var count: Int { return phAssetsStub.count }
}

class TestCollectionFetchResult: PHFetchResult<PHAssetCollection> {
    var phAssetCollectionStub: [PHAssetCollection]!
    var bool = ObjCBool(false)
    
    override func enumerateObjects(_ block: @escaping (PHAssetCollection, Int, UnsafeMutablePointer<ObjCBool>) -> Void) {
        for i in 0 ..< phAssetCollectionStub.count {
            block(phAssetCollectionStub[i], i, &bool)
        }
    }
    override var count: Int { return phAssetCollectionStub.count }
    override var firstObject: PHAssetCollection? { return phAssetCollectionStub.first }
}

class TestCollectionListFetchResult: PHFetchResult<PHCollectionList> {
    var phCollectionListStub: [PHCollectionList]!
    var bool = ObjCBool(false)
    
    override func enumerateObjects(_ block: @escaping (PHCollectionList, Int, UnsafeMutablePointer<ObjCBool>) -> Void) {
        for i in 0 ..< phCollectionListStub.count {
            block(phCollectionListStub[i], i, &bool)
        }
    }
    override var count: Int { return phCollectionListStub.count }
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

// MARK: - Dependency injection test classes

// Conforms to the AssetManager protocol to get around dependencies on static methods for PHAsset
class TestAssetManager: AssetManager {
    
    var phAssetsStub: [TestPHAsset]?
    
    func fetchAsset(withLocalIdentifier identifier: String, options: PHFetchOptions?) -> PHAsset? {
        return phAssetsStub?.first
    }
    
    func fetchAssets(in assetCollection: PHAssetCollection, options: PHFetchOptions) -> PHFetchResult<PHAsset> {
        guard let assets = phAssetsStub, let assetCollection = assetCollection as? TestPHAssetCollection else { return TestAssetFetchResult() }
        let fetchResult = TestAssetFetchResult()
        fetchResult.phAssetsStub = assets.filter { $0.listIdentifier == assetCollection.localIdentifier }
        return fetchResult
    }
}

class TestCollectionManager: CollectionManager {
    var phAssetCollectionStub: [TestPHAssetCollection]?
    
    func fetchMoments(inMomentList collectionList: PHCollectionList) -> PHFetchResult<PHAssetCollection> {
        guard let assetCollection = phAssetCollectionStub else { return TestCollectionFetchResult() }
        let fetchResult = TestCollectionFetchResult()
        fetchResult.phAssetCollectionStub = assetCollection.filter { $0.listIdentifier == collectionList.localIdentifier }
        return fetchResult
    }
}

class TestCollectionListManager: CollectionListManager {
    var phCollectionListStub: [TestPHCollectionList]?

    func fetchMomentLists(options: PHFetchOptions?) -> PHFetchResult<PHCollectionList> {
        guard var collectionList = phCollectionListStub else { return TestCollectionListFetchResult() }
        if let predicate = options?.predicate {
            collectionList = collectionList.filter { predicate.evaluate(with: $0) }
        }
        if let sortDescriptors = options?.sortDescriptors {
            collectionList = ((collectionList as NSArray).sortedArray(using: sortDescriptors)) as! [TestPHCollectionList]
        }
        
        let fetchResult = TestCollectionListFetchResult()
        fetchResult.phCollectionListStub = collectionList
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

class TestFacebookApiManager: FacebookApiManager {

    var result: Any?
    var error: LocalizedError?
    var lastPath: String?
    
    var accessToken: String?
    func request(withGraphPath path: String, parameters: [String: Any]?, completion: @escaping (Any?, Error?) -> Void) {
        self.lastPath = path
        completion(result, error)
    }
}

class TestInstagramApiManager: InstagramApiManager {
    
    var data: Any?
    var error: OAuthSwiftError?
    var credential: OAuthSwiftCredential?
    var lastUrl: String?
    
    func startAuthorizedRequest(_ url: String,
                                method: OAuthSwiftHTTPRequest.Method,
                                onTokenRenewal: OAuthSwift.TokenRenewedHandler?,
                                success: @escaping OAuthSwiftHTTPRequest.SuccessHandler,
                                failure: @escaping OAuthSwiftHTTPRequest.FailureHandler) {
        lastUrl = url
        if let credential = credential { onTokenRenewal?(credential) }
        if let error = error { failure(error) }
        else if let data = data {
            let serialized = try! JSONSerialization.data(withJSONObject: data, options: [])
            let httpResponse = HTTPURLResponse(url: testUrl, mimeType: "text/html", expectedContentLength: 0, textEncodingName: nil)
            let response = OAuthSwiftResponse(data: serialized, response: httpResponse, request: nil)
            success(response)
        }
    }
}

class TestKeychainHandler: NSObject, KeychainHandler {
    var tokenKey: String?
}
