//
//  Modified MIT License
//
//  Copyright (c) 2010-2018 Kite Tech Ltd. https://www.kite.ly
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The software MAY ONLY be used with the Kite Tech Ltd platform and MAY NOT be modified
//  to be used with any competitor platforms. This means the software MAY NOT be modified
//  to place orders with any competitors to Kite Tech Ltd, all orders MUST go through the
//  Kite Tech Ltd platform servers.
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation
import Photos
import OAuthSwift
@testable import Photobook_App

// MARK: - Photo Library object mocks
class PHAssetMock: PHAsset {
    
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

class PHAssetCollectionMock: PHAssetCollection {
    var localIdentifierStub: String? = "assetCollection"
    var listIdentifier: String?
    override var localIdentifier: String { return localIdentifierStub ?? "id" }
}

class PHCollectionListMock: PHCollectionList {
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
class AssetFetchResultMock: PHFetchResult<PHAsset> {
    var phAssetsStub: [PHAsset]!
    var bool = ObjCBool(false)
    
    override func enumerateObjects(_ block: @escaping (PHAsset, Int, UnsafeMutablePointer<ObjCBool>) -> Void) {
        for i in 0 ..< phAssetsStub.count {
            block(phAssetsStub[i], i, &bool)
        }
    }
    override var count: Int { return phAssetsStub.count }
}

class CollectionFetchResultMock: PHFetchResult<PHAssetCollection> {
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

class CollectionListFetchResultMock: PHFetchResult<PHCollectionList> {
    var phCollectionListStub: [PHCollectionList]!
    var bool = ObjCBool(false)
    
    override func enumerateObjects(_ block: @escaping (PHCollectionList, Int, UnsafeMutablePointer<ObjCBool>) -> Void) {
        for i in 0 ..< phCollectionListStub.count {
            block(phCollectionListStub[i], i, &bool)
        }
    }
    override var count: Int { return phCollectionListStub.count }
}

class FetchResultChangeDetailsMock: PHFetchResultChangeDetails<PHAsset> {
    var phInsertedAssetsStub: [PHAsset]!
    var phRemovedAssetsStub: [PHAsset]!

    override var insertedObjects: [PHAsset] { return phInsertedAssetsStub }
    override var removedObjects: [PHAsset] { return phRemovedAssetsStub }
}

class ChangeManagerMock: ChangeManager {
    var phInsertedAssetsStub: [PHAsset]!
    var phRemovedAssetsStub: [PHAsset]!
    
    func details(for fetchResult: PHFetchResult<PHAsset>) -> PHFetchResultChangeDetails<PHAsset>? {
        let testFetchResultChangeDetails = FetchResultChangeDetailsMock()
        testFetchResultChangeDetails.phInsertedAssetsStub = phInsertedAssetsStub
        testFetchResultChangeDetails.phRemovedAssetsStub = phRemovedAssetsStub
        return testFetchResultChangeDetails
    }
}

// MARK: - Dependency injection test classes


class CollectionManagerMock: CollectionManager {
    var phAssetCollectionStub: [PHAssetCollectionMock]?
    
    func fetchMoments(inMomentList collectionList: PHCollectionList) -> PHFetchResult<PHAssetCollection> {
        guard let assetCollection = phAssetCollectionStub else { return CollectionFetchResultMock() }
        let fetchResult = CollectionFetchResultMock()
        fetchResult.phAssetCollectionStub = assetCollection.filter { $0.listIdentifier == collectionList.localIdentifier }
        return fetchResult
    }
}

class CollectionListManagerMock: CollectionListManager {
    var phCollectionListStub: [PHCollectionListMock]?

    func fetchMomentLists(options: PHFetchOptions?) -> PHFetchResult<PHCollectionList> {
        guard var collectionList = phCollectionListStub else { return CollectionListFetchResultMock() }
        if let predicate = options?.predicate {
            collectionList = collectionList.filter { predicate.evaluate(with: $0) }
        }
        if let sortDescriptors = options?.sortDescriptors {
            collectionList = ((collectionList as NSArray).sortedArray(using: sortDescriptors)) as! [PHCollectionListMock]
        }
        
        let fetchResult = CollectionListFetchResultMock()
        fetchResult.phCollectionListStub = collectionList
        return fetchResult
    }
}

class PHImageManagerMock: PHImageManager {
    
    var imageData: Data!
    var dataUti: String!
    
    override func requestImage(for asset: PHAsset, targetSize: CGSize, contentMode: PHImageContentMode, options: PHImageRequestOptions?, resultHandler: @escaping (UIImage?, [AnyHashable : Any]?) -> Void) -> PHImageRequestID {
        
        let image = UIImage(color: .black, size: targetSize)
        
        resultHandler(image, nil)
        
        return 0
    }
    
    override func requestImageData(for asset: PHAsset, options: PHImageRequestOptions?, resultHandler: @escaping (Data?, String?, UIImage.Orientation, [AnyHashable : Any]?) -> Void) -> PHImageRequestID {
        
        resultHandler(imageData, dataUti, .up, nil)
        
        return 0
    }
}

class FacebookApiManagerMock: FacebookApiManager {

    var result: Any?
    var error: LocalizedError?
    var lastPath: String?
    
    var accessToken: String?
    func request(withGraphPath path: String, parameters: [String: Any]?, completion: @escaping (Any?, Error?) -> Void) {
        self.lastPath = path
        completion(result, error)
    }
}

class InstagramApiManagerMock: InstagramApiManager {
    
    var data: Any?
    var error: OAuthSwiftError?
    var credential: OAuthSwiftCredential?
    var lastUrl: String?
    
    func startAuthorizedRequest(_ url: String, method: OAuthSwiftHTTPRequest.Method, onTokenRenewal: OAuthSwift.TokenRenewedHandler?, completionHandler: @escaping OAuthSwiftHTTPRequest.CompletionHandler) {
        lastUrl = url
        if let credential = credential { onTokenRenewal?(.success(credential)) }
        if let error = error { completionHandler(.failure(error)) }
        else if let data = data {
            let serialized = try! JSONSerialization.data(withJSONObject: data, options: [])
            let httpResponse = HTTPURLResponse(url: testUrl, mimeType: "text/html", expectedContentLength: 0, textEncodingName: nil)
            let response = OAuthSwiftResponse(data: serialized, response: httpResponse, request: nil)
            completionHandler(.success(response))
        }
    }
}

class KeychainHandlerMock: NSObject, KeychainHandler {
    var tokenKey: String?
}
