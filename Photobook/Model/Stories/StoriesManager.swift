//
//  StoriesManager.swift
//  Photobook
//
//  Created by Jaime Landazuri on 09/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import Photos

struct StoriesNotificationName {
    static let storiesWereUpdated = Notification.Name("ly.kite.sdk.storiesWereUpdatedNotificationName")
}

class StoriesManager: NSObject {
    
    enum StoriesManagerError: Error {
        case unauthorized
        case incompatibleAssetType
    }
    
    // Shared client
    static let shared = StoriesManager()
    
    private let imageManager = PHCachingImageManager()
    private var selectedAssetsManagerPerStory = [String : SelectedAssetsManager]()
    var stories = [Story]()
    var currentlySelectedStory: Story?
    var loading = false
    private var fromBackground = false
    
    private struct Constants {
        static let maxStoriesToDisplay = 16
    }
    
    override init() {
        super.init()
        PHPhotoLibrary.shared().register(self)
        NotificationCenter.default.addObserver(self, selector: #selector(resetStoriesSelections), name: ReceiptNotificationName.receiptWillDismiss, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appRestoredFromBackground), name: .UIApplicationDidBecomeActive, object: nil)
        NotificationCenter.default.addObserver(forName: .UIApplicationDidEnterBackground, object: nil, queue: OperationQueue.main, using: { [weak welf = self] _ in
            welf?.fromBackground = true
        })
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func loadTopStories(completionHandler:(() -> Void)? = nil) {
        guard !loading, stories.isEmpty else { completionHandler?(); return }
        
        loading = true
        DispatchQueue.global(qos: .background).async { [weak welf = self] in
            let memories = self.orderStories()
            let newStories = Array<Story>(memories.prefix(Constants.maxStoriesToDisplay))
            
            guard let stelf = welf else { return }
            
            var storiesChanged = newStories.count != stelf.stories.count
            for index in 0..<newStories.count {
                guard !storiesChanged else { break }
                storiesChanged = newStories[index].title != stelf.stories[index].title || newStories[index].subtitle != stelf.stories[index].subtitle
            }
            
            welf?.stories = newStories
            DispatchQueue.main.async {
                welf?.loading = false
                completionHandler?()
                
                if storiesChanged {
                    NotificationCenter.default.post(name: StoriesNotificationName.storiesWereUpdated, object: nil)
                }
            }
        }
    }
    
    func prepare(story: Story, completionHandler:@escaping () -> Void) {
        DispatchQueue.global(qos: .background).async {
            story.loadAssets(completionHandler: { [weak welf = self] _ in
                welf?.performAutoSelectionIfNeeded(on: story)
                DispatchQueue.main.async {
                    completionHandler()
                }
            })
        }
    }
    
    @objc private func appRestoredFromBackground() {
        // If stories are loaded from application(_:didFinishLaunchingWithOptions:), make sure we don't load the stories twice, slowing down launch time
        if (fromBackground) {
            loadTopStories()
        }
    }

    private func orderStories() -> [Story] {
        var locations = [String: Int]()
        var stories = [Story]()
        
        // Request memories no older than 3 years
        let threeYearsAgo = Calendar.current.date(byAdding: .year, value: -3, to: Date())
        
        let options = PHFetchOptions()
        options.predicate = NSPredicate(format: "startDate > %@", threeYearsAgo! as CVarArg)
        options.sortDescriptors = [ NSSortDescriptor(key: "endDate", ascending: false) ]
        
        let momentLists = PHCollectionList.fetchMomentLists(with: .momentListCluster, options: options)
        momentLists.enumerateObjects { [weak welf = self] (list: PHCollectionList, index: Int, stop: UnsafeMutablePointer<ObjCBool>) in
            // Access individual moments and get the total estimated photo count
            var totalAssetCount = 0
            
            let moments = PHAssetCollection.fetchMoments(inMomentList: list, options: PHFetchOptions())
            
            
            moments.enumerateObjects { (collection: PHAssetCollection, index: Int,  stop: UnsafeMutablePointer<ObjCBool>) in
                //only use images
                let fetchOptions = PHFetchOptions()
                fetchOptions.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)
                let filteredCollection = PHAsset.fetchAssets(in: collection, options: fetchOptions)
                
                totalAssetCount += filteredCollection.count
            }
            
            // Must also have a title
            guard let title = list.localizedTitle else { return }
            
            // Break down the cluster title into different locations
            let locationComponents = self.breakDownLocation(title: title)
            
            for component in locationComponents {
                if let locationItem = locations[component] {
                    locations[component] = locationItem + 1
                    continue
                }
                locations[component] = 1
            }
            
            // Minimum asset count
            guard totalAssetCount > ProductManager.shared.minimumRequiredAssets else { return }
            
            let story = Story(list: list, coverCollection: moments.firstObject!)
            story.components = locationComponents
            story.photoCount = totalAssetCount
            welf?.selectedAssetsManagerPerStory[story.identifier] = SelectedAssetsManager()
            
            stories.append(story)
        }
        
        let orderedLocations = locations.sorted { $0.value > $1.value }.map { return $0.key }
        
        for story in stories {
            
            // Photo count
            if story.photoCount > 100 {
                story.score += -20
            }
            
            // Determine location occurrence score
            let locationOcurrences = story.components.reduce(0, { (result, string) -> Int in
                return result + locations[string]!
            })
            
            // Penalise memory clusters with common locations
            if locationOcurrences > 5 {
                story.score += -20
            }
            
            if let endDate = story.collectionList.endDate {
                // Is it recent?
                let componentsMonthCheck = NSCalendar.current.dateComponents([.day], from: endDate, to: Date())
                let years = Double(componentsMonthCheck.day!) / 365.0
                if componentsMonthCheck.day! < 30 {
                    story.score += 30
                } else if componentsMonthCheck.day! < 90 {
                    story.score += 10
                } else if years >= 1 && years < 3 {
                    story.score += -20
                }
                
                if let startDate = story.collectionList.startDate {
                    // Is it a trip?
                    
                    // Check if the locations are among the most visited
                    var hasCommonLocation = false
                    for component in story.components {
                        if orderedLocations.index(of: component)! <= Int(Double(component.count) * 0.2) {
                            hasCommonLocation = true
                            break
                        }
                    }
                    
                    let componentsTripCheck = NSCalendar.current.dateComponents([.day], from: startDate, to: endDate)
                    if componentsTripCheck.day! > 3 && componentsTripCheck.day! < 20  {
                        if !hasCommonLocation {
                            story.score += 20
                        } else {
                            story.score -= 10
                        }
                    } else if componentsTripCheck.day! <= 3 {
                        // Is it a weekend event?
                        let startWeekDay = NSCalendar(identifier: .gregorian)!.component(.weekday, from: startDate)
                        let endWeekDay = NSCalendar(identifier: .gregorian)!.component(.weekday, from: endDate)
                        if (startWeekDay == 6 || startWeekDay == 7) &&  // Friday or Saturday
                            (endWeekDay == 1 || endWeekDay == 2) {  // Sunday or Monday
                            story.score += 10
                            story.isWeekend = true
                        }
                    }
                }
            }
        }
        
        let sortedStories = stories.sorted { (lhs, rhs) -> Bool in
            lhs.score > rhs.score || (lhs.score == rhs.score && lhs.collectionList.endDate! > rhs.collectionList.endDate!)
        }
        
        return sortedStories
    }
    
    private func breakDownLocation(title location: String) -> [String] {
        if let mainLocation = location.index(of: "-") {
            return [ String(location.prefix(upTo: mainLocation)) ]
        }
        return location.components(separatedBy: CharacterSet(charactersIn: ",&")).map { (item) -> String in
            return item.trimmingCharacters(in: CharacterSet(charactersIn: " "))
        }
    }
    
    func selectedAssetsManager(for story: Story) -> SelectedAssetsManager?{
        return selectedAssetsManagerPerStory[story.identifier]
    }
    
    func performAutoSelectionIfNeeded(on story: Story) {
        if !story.hasPerformedAutoSelection {
            performAutoSelection(on: story)
        }
    }
    
    private func performAutoSelection(on story: Story) {
        var selectedAssets = [Asset]()
        var unusedAssets = [Asset]()
        
        let minimumAssets = ProductManager.shared.minimumRequiredAssets
        let subarrayLength = minimumAssets // For readability
        let subarrayCount: Int = story.photoCount / subarrayLength
        let assetsFromEachSubarray: Int = minimumAssets / subarrayCount
        
        for subarrayIndex in 0..<subarrayCount {
            
            let subarrayStartIndex = subarrayIndex * subarrayLength
            // The last subarray will take on any leftovers resulting from integer division
            var subarray = Array(subarrayIndex == subarrayCount - 1 ? story.assets[subarrayStartIndex...] : story.assets[subarrayStartIndex..<subarrayStartIndex + subarrayLength])
            
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
        
        let selectedAssetsManager = selectedAssetsManagerPerStory[story.identifier]
        selectedAssetsManager?.select(selectedAssets)
        
        // Sort
        selectedAssetsManager?.orderAssetsByDate()
        
        story.hasPerformedAutoSelection = true
    }
    
    @objc private func resetStoriesSelections() {
        for story in stories {
            selectedAssetsManagerPerStory[story.identifier]?.deselectAllAssetsForAllAlbums()
            story.hasPerformedAutoSelection = false
        }
    }
}

extension StoriesManager: PHPhotoLibraryChangeObserver {
    
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        // We only care for the currently selected story
        guard let story = currentlySelectedStory else { return }
        
        var albumChanges = [AlbumChange]()
        
        DispatchQueue.main.sync {
            var assetsRemoved = [Asset]()
            var indexesRemoved = [Int]()
            for asset in story.assets {
                guard let asset = asset as? PhotosAsset else { continue }
                if let changeDetails = changeInstance.changeDetails(for: asset.photosAsset),
                    changeDetails.objectWasDeleted {
                    assetsRemoved.append(asset)
                    
                    if let index = story.assets.index(where: { $0.identifier == asset.identifier}) {
                        indexesRemoved.append(index)
                    }
                }
            }
            albumChanges.append(AlbumChange(album: story, assetsRemoved: assetsRemoved, indexesRemoved: indexesRemoved, assetsAdded: []))
            
            // Remove assets from this story from the end as to not mess up the indexes
            for assetIndex in indexesRemoved.reversed() {
                story.assets.remove(at: assetIndex)
            }
            
            if !albumChanges.isEmpty {
                NotificationCenter.default.post(name: AssetsNotificationName.albumsWereUpdated, object: albumChanges)
            }
        }
    }
    
}
