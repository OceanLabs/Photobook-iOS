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

import Photos
import Photobook

protocol CollectionManager {
    func fetchMoments(inMomentList collectionList: PHCollectionList) -> PHFetchResult<PHAssetCollection>
}

class DefaultCollectionManager: CollectionManager {
    func fetchMoments(inMomentList collectionList: PHCollectionList) -> PHFetchResult<PHAssetCollection> {
        return PHAssetCollection.fetchMoments(inMomentList: collectionList, options: PHFetchOptions())
    }
}

class Story: Codable {
    private(set) var title: String!
    private(set) var collectionList: PHCollectionList!
    private(set) var collectionForCoverPhoto: PHAssetCollection!
    var components: [String]!
    var photoCount = 0
    var isWeekend = false
    var score = 0
    var assets = [PhotobookAsset]()
    var hasMoreAssetsToLoad = false
    
    // Ability to set locale in Unit Tests
    lazy var locale = Locale.current
    
    lazy var collectionManager: CollectionManager = DefaultCollectionManager()
    lazy var assetsManager: AssetManager = DefaultAssetManager()
    
    lazy var subtitle: String? = {
        if isWeekend {
            return String.localizedStringWithFormat(NSLocalizedString("stories/story/date", value: "WEEKEND IN %@",
                                  comment: "A subtitle for a story identified as a weekend"), dateString().uppercased())
        }
        return dateString().uppercased()
    }()
    
    convenience init(list: PHCollectionList, storyTitle: String, coverCollection: PHAssetCollection) {
        self.init()
        
        title = storyTitle.uppercased()
        collectionList = list
        collectionForCoverPhoto = coverCollection
    }
    
    private enum CodingKeys: String, CodingKey {
        case identifier, coverIdentifier
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(identifier, forKey: .identifier)
    }
    
    convenience required init(from decoder: Decoder) throws {
        self.init()
        
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let collectionListIdentifier = try values.decode(String.self, forKey: .identifier)
        
        guard let collectionList = PHCollectionList.fetchCollectionLists(withLocalIdentifiers: [collectionListIdentifier], options: nil).firstObject,
              let momentForCover = collectionManager.fetchMoments(inMomentList: collectionList).firstObject else {
            throw AssetDataSourceException.notFound
        }
        
        self.collectionList = collectionList
        self.collectionForCoverPhoto = momentForCover
    }
    
    private func dateString() -> String {
        guard let startDate = collectionList.startDate, let endDate = collectionList.endDate else { return "" }
        
        let dateFormatter = DateFormatter()
        
        // Check if it's same day
        if NSCalendar.current.isDate(startDate, inSameDayAs: endDate) {
            dateFormatter.dateStyle = .medium
            dateFormatter.locale = locale
            return dateFormatter.string(from: startDate)
        }
        
        let startDateComponents = NSCalendar.current.dateComponents([.day, .month, .year], from: startDate)
        let endDateComponents = NSCalendar.current.dateComponents([.day, .month, .year], from: endDate)
        
        // Different years
        if startDateComponents.year != endDateComponents.year {
            dateFormatter.dateFormat = "MMM yyyy"
            return dateFormatter.string(from: startDate) + " - " + dateFormatter.string(from: endDate)
        }
        
        // Same year, different months
        if startDateComponents.month != endDateComponents.month {
            dateFormatter.dateFormat = "MMM - "
            let firstMonth = dateFormatter.string(from: startDate)
            
            dateFormatter.dateFormat = "MMM yyyy"
            let secondMonth = dateFormatter.string(from: endDate)
            
            return firstMonth + secondMonth
        }
        
        // Same month
        dateFormatter.dateFormat = "MMM yyyy"
        return dateFormatter.string(from: startDate)
    }
}

extension Story: Album {
    
    var numberOfAssets: Int {
        return photoCount
    }
    
    var localizedName: String? {
        return ""
    }
    
    var identifier: String {
        return collectionList.localIdentifier
    }
    
    func loadAssets(completionHandler: ((Error?) -> Void)?) {
        guard assets.isEmpty else {
            completionHandler?(nil)
            return
        }
        
        let fetchOptions = PHFetchOptions()
        fetchOptions.wantsIncrementalChangeDetails = false
        fetchOptions.includeHiddenAssets = false
        fetchOptions.includeAllBurstAssets = false
        
        let moments = collectionManager.fetchMoments(inMomentList: collectionList)
        moments.enumerateObjects { (collection: PHAssetCollection, index: Int,  stop: UnsafeMutablePointer<ObjCBool>) in
            
            fetchOptions.sortDescriptors = [ NSSortDescriptor(key: "creationDate", ascending: true) ]
            fetchOptions.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue) // Only images
            
            let fetchedAssets = self.assetsManager.fetchAssets(in: collection, options: fetchOptions)
            fetchedAssets.enumerateObjects({ (asset, _, _) in
                let photobookAsset = PhotobookAsset(withPHAsset: asset, albumIdentifier: self.identifier)
                self.assets.append(photobookAsset)
            })
        }
        
        completionHandler?(nil)
    }
    
    func coverAsset(completionHandler: @escaping (PhotobookAsset?) -> Void) {
        collectionForCoverPhoto.coverAsset(useFirstImageInCollection: true, completionHandler: completionHandler)
    }
    
    func loadNextBatchOfAssets(completionHandler: ((Error?) -> Void)?) {}
}

extension Story: PickerAnalytics {
    var selectingPhotosScreenName: Analytics.ScreenName { return .storiesPicker }
    var addingMorePhotosScreenName: Analytics.ScreenName { return .storiesPickerAddingMorePhotos }
}

