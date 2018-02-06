//
//  Story.swift
//  Photobook
//
//  Created by Jaime Landazuri on 09/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import Photos

class Story {
    private enum StoryError: Error {
        case assetType
    }
    
    let collectionList: PHCollectionList
    let collectionForCoverPhoto: PHAssetCollection
    let selectedAssetsManager = SelectedAssetsManager()
    var components: [String]!
    var photoCount = 0
    var isWeekend = false
    var score = 0
    var assets = [Asset]()
    private var hasPerformedAutoSelection = false
    
    // Ability to set locale in Unit Tests
    lazy var locale = Locale.current
    
    var title: String {
        return collectionList.localizedTitle!.uppercased()
    }
    
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
    
    func performAutoSelectionIfNeeded() {
        guard !hasPerformedAutoSelection else { return }
        
        var selectedAssets = [Asset]()
        var unusedAssets = [Asset]()
        
        let minimumAssets = ProductManager.shared.minimumRequiredAssets
        let subarrayLength = minimumAssets // For readability
        let subarrayCount: Int = photoCount / subarrayLength
        let assetsFromEachSubarray: Int = minimumAssets / subarrayCount
        
        for subarrayIndex in 0..<subarrayCount {
            
            let subarrayStartIndex = subarrayIndex * subarrayLength
            // The last subarray will take on any leftovers resulting from integer division
            var subarray = Array(subarrayIndex == subarrayCount - 1 ? assets[subarrayStartIndex...] : assets[subarrayStartIndex..<subarrayStartIndex + subarrayLength])
            
            for _ in 0..<assetsFromEachSubarray {
                let selectedIndex = Int(arc4random()) % subarray.count
                selectedAssets.append(subarray.remove(at: selectedIndex))
            }
            unusedAssets.append(contentsOf: subarray)
        }
        
        // In case we have come up short because of all the integer divisions we have done above, select some more assets from the unused ones if needed.
        while selectedAssets.count < minimumAssets {
            let selectedIndex = Int(arc4random()) % unusedAssets.count
            selectedAssets.append(unusedAssets.remove(at: selectedIndex))
        }
        
        // Sort
        try? selectedAssets.sort(by: {
            guard let d1 = ($0 as? PhotosAsset)?.photosAsset.creationDate,
                let d2 = ($1 as? PhotosAsset)?.photosAsset.creationDate else { throw StoryError.assetType }
            return d1 < d2
        })
        
        selectedAssetsManager.select(selectedAssets)
        hasPerformedAutoSelection = true
    }
}

extension Story: Album {
    
    var numberOfAssets: Int {
        return photoCount
    }
    
    var localizedName: String? {
        return title
    }
    
    var identifier: String {
        return collectionList.localIdentifier
    }
    
    func loadAssets(completionHandler: ((Error?) -> Void)?) {
        let fetchOptions = PHFetchOptions()
        fetchOptions.wantsIncrementalChangeDetails = false
        fetchOptions.includeHiddenAssets = false
        fetchOptions.includeAllBurstAssets = false
        
        let moments = PHAssetCollection.fetchMoments(inMomentList: collectionList, options: PHFetchOptions())
        moments.enumerateObjects { (collection: PHAssetCollection, index: Int,  stop: UnsafeMutablePointer<ObjCBool>) in
            
            fetchOptions.sortDescriptors = [ NSSortDescriptor(key: "creationDate", ascending: false) ]
            let fetchedAssets = PHAsset.fetchAssets(in: collection, options: fetchOptions)
            fetchedAssets.enumerateObjects({ (asset, _, _) in
                self.assets.append(PhotosAsset(asset, albumIdentifier: self.identifier))
            })
        }
        
        completionHandler?(nil)
    }
    
    func coverImage(size: CGSize, completionHandler: @escaping (UIImage?, Error?) -> Void) {
        collectionForCoverPhoto.coverImage(size: size, completionHandler: completionHandler)
    }
}

