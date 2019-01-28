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

import UIKit
import Photos
import Photobook

protocol ChangeManager {
    func details(for fetchResult: PHFetchResult<PHAsset>) -> PHFetchResultChangeDetails<PHAsset>?
}

extension PHChange: ChangeManager {
    func details(for fetchResult: PHFetchResult<PHAsset>) -> PHFetchResultChangeDetails<PHAsset>? {
        return changeDetails(for: fetchResult)
    }
}

enum AssetLoadingException: Error {
    case notFound
}

class PhotosAlbum: Album, Codable {
    
    let assetCollection: PHAssetCollection
    var assets = [PhotobookAsset]()
    var hasMoreAssetsToLoad = false

    private var fetchedAssets: PHFetchResult<PHAsset>?
    lazy var assetManager: AssetManager = DefaultAssetManager()
    
    init(_ assetCollection: PHAssetCollection) {
        self.assetCollection = assetCollection
    }
    
    private enum CodingKeys: String, CodingKey {
        case identifier
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(identifier, forKey: .identifier)
    }
    
    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        let collectionId = try values.decode(String.self, forKey: .identifier)
        let fetchResult = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [collectionId], options: nil)
        if let assetCollection = fetchResult.firstObject {
            self.assetCollection = assetCollection
            loadAssetsFromPhotoLibrary()
            return
        }
        throw AssetLoadingException.notFound
    }

    /// Returns the estimated number of assets for this album, which might not be available without calling loadAssets. It might differ from the actual number of assets. NSNotFound if not available.
    var numberOfAssets: Int {
        return !assets.isEmpty ? assets.count : assetCollection.estimatedAssetCount
    }
    
    var localizedName: String? {
        return assetCollection.localizedTitle
    }
    
    var identifier: String {
        return assetCollection.localIdentifier
    }
    
    func loadAssets(completionHandler: ((Error?) -> Void)?) {
        DispatchQueue.global(qos: .default).async { [weak welf = self] in
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
        fetchOptions.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)
        fetchOptions.sortDescriptors = [ NSSortDescriptor(key: "creationDate", ascending: false) ]
        let fetchedAssets = assetManager.fetchAssets(in: assetCollection, options: fetchOptions)
        var assets = [PhotobookAsset]()
        fetchedAssets.enumerateObjects({ (asset, _, _) in
            let photobookAsset = PhotobookAsset(withPHAsset: asset, albumIdentifier: self.identifier)
            assets.append(photobookAsset)
        })
        
        self.assets = assets
        self.fetchedAssets = fetchedAssets
    }
    
    func coverAsset(completionHandler: @escaping (PhotobookAsset?) -> Void) {
        assetCollection.coverAsset(useFirstImageInCollection: false, completionHandler: completionHandler)
    }
    
    func loadNextBatchOfAssets(completionHandler: ((Error?) -> Void)?) {}
    
    func changedAssets(for changeInstance: ChangeManager) -> ([PhotobookAsset]?, [PhotobookAsset]?) {
        guard let fetchedAssets = fetchedAssets,
            let changeDetails = changeInstance.details(for: fetchedAssets)
        else { return (nil, nil) }
        
        var insertedObjects = changeDetails.insertedObjects.map { PhotobookAsset(withPHAsset: $0, albumIdentifier: identifier)  }
        insertedObjects = insertedObjects.filter { !assets.contains($0) }
        
        var removedObjects = changeDetails.removedObjects.map { PhotobookAsset(withPHAsset: $0, albumIdentifier: identifier)  }
        removedObjects = removedObjects.filter { assets.contains($0) }
        
        return (insertedObjects, removedObjects)
    }
}

extension PhotosAlbum: PickerAnalytics {
    var selectingPhotosScreenName: Analytics.ScreenName { return .picker }
    var addingMorePhotosScreenName: Analytics.ScreenName { return .pickerAddingMorePhotos }
}
