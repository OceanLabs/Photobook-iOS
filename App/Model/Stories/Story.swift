//
//  Story.swift
//  Photobook
//
//  Created by Jaime Landazuri on 09/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import Photos

protocol CollectionManager {
    func fetchMoments(inMomentList collectionList: PHCollectionList) -> PHFetchResult<PHAssetCollection>
}

class DefaultCollectionManager: CollectionManager {
    func fetchMoments(inMomentList collectionList: PHCollectionList) -> PHFetchResult<PHAssetCollection> {
        return PHAssetCollection.fetchMoments(inMomentList: collectionList, options: PHFetchOptions())
    }
}

class Story {
    let collectionList: PHCollectionList
    let collectionForCoverPhoto: PHAssetCollection
    var components: [String]!
    var photoCount = 0
    var isWeekend = false
    var score = 0
    var assets = [Asset]()
    var hasMoreAssetsToLoad = false
    var hasPerformedAutoSelection = false
    
    // Ability to set locale in Unit Tests
    lazy var locale = Locale.current
    
    var title: String {
        return collectionList.localizedTitle!.uppercased()
    }
    
    lazy var collectionManager: CollectionManager = DefaultCollectionManager()
    lazy var assetsManager: AssetManager = DefaultAssetManager()
    
    lazy var subtitle: String? = {
        if isWeekend {
            return String.localizedStringWithFormat(NSLocalizedString("stories/story/date", value: "WEEKEND IN %@",
                                  comment: "A subtitle for a story identified as a weekend"), dateString().uppercased())
        }
        return dateString().uppercased()
    }()
    
    init(list: PHCollectionList, coverCollection: PHAssetCollection) {
        collectionList = list
        collectionForCoverPhoto = coverCollection
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
                self.assets.append(PhotosAsset(asset, albumIdentifier: self.identifier))
            })
        }
        
        completionHandler?(nil)
    }
    
    func coverAsset(completionHandler: @escaping (Asset?, Error?) -> Void) {
        collectionForCoverPhoto.coverAsset(useFirstImageInCollection: true, completionHandler: completionHandler)
    }
    
    func loadNextBatchOfAssets(completionHandler: ((Error?) -> Void)?) {}
}

extension Story: PickerAnalytics {
    var selectingPhotosScreenName: Analytics.ScreenName { return .storiesPicker }
    var addingMorePhotosScreenName: Analytics.ScreenName { return .storiesPickerAddingMorePhotos }
}

