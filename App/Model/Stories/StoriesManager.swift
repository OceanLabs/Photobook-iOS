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

protocol CollectionListManager {
    func fetchMomentLists(options: PHFetchOptions?) -> PHFetchResult<PHCollectionList>
}

class DefaultCollectionListManager: CollectionListManager {
    func fetchMomentLists(options: PHFetchOptions?) -> PHFetchResult<PHCollectionList> {
        return PHCollectionList.fetchMomentLists(with: .momentListCluster, options: options)
    }
}

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
    var stories = [Story]()
    var currentlySelectedStory: Story?
    var loading = false
    private var fromBackground = false
    
    private struct Constants {
        static let maxStoriesToDisplay = 16
    }
    
    lazy var collectionListManager: CollectionListManager = DefaultCollectionListManager()
    lazy var collectionManager: CollectionManager = DefaultCollectionManager()
    lazy var assetManager: AssetManager = DefaultAssetManager()
    
    override init() {
        super.init()
        PHPhotoLibrary.shared().register(self)
        NotificationCenter.default.addObserver(self, selector: #selector(appRestoredFromBackground), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: OperationQueue.main, using: { [weak welf = self] _ in
            welf?.fromBackground = true
        })
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func loadTopStories(completionHandler:(() -> Void)? = nil) {
        guard !loading, stories.isEmpty else { completionHandler?(); return }
        
        var serviceQuality = DispatchQoS.QoSClass.default
        #if DEBUG
        if !PhotobookApp.isRunningUnitTests() {
            serviceQuality = DispatchQoS.QoSClass.userInteractive
        }
        #endif
        loading = true
        DispatchQueue.global(qos: serviceQuality).async { [weak welf = self] in
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
    
    func prepare(story: Story, completionHandler: @escaping () -> Void) {
        DispatchQueue.global(qos: .default).async {
            story.loadAssets(completionHandler: { _ in
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
        
        let momentLists = collectionListManager.fetchMomentLists(options: options)
        momentLists.enumerateObjects { [weak welf = self] (list: PHCollectionList, index: Int, stop: UnsafeMutablePointer<ObjCBool>) in
            // Access individual moments and get the total estimated photo count
            var totalAssetCount = 0
            
            guard let moments = welf?.collectionManager.fetchMoments(inMomentList: list) else { return }
            moments.enumerateObjects { (collection: PHAssetCollection, index: Int,  stop: UnsafeMutablePointer<ObjCBool>) in
                //only use images
                let fetchOptions = PHFetchOptions()
                fetchOptions.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)
                guard let filteredCollection = welf?.assetManager.fetchAssets(in: collection, options: fetchOptions) else { return }
                
                totalAssetCount += filteredCollection.count
            }
            
            var locationComponents = [String]()
            var storyTitle: String?
            if let title = list.localizedTitle {
                // Break down the cluster title into different locations
                storyTitle = title
                locationComponents = self.breakDownLocation(title: title)
            } else {
                // The Photo Library seems to be phasing out moment lists as of iOS 13 and they don't have a title after the update.
                // If that's the case, use the individual moments to work out a title
                var locationsDictionary = [String: Int]()
                for i in 0 ..< moments.count {
                    guard let title = moments[i].localizedTitle else { continue }
                    let locationCount = locationsDictionary[title] ?? 0
                    locationsDictionary[title] = locationCount + 1
                }
                let locationsSorted = locationsDictionary.sorted { $0.value > $1.value }
                storyTitle = locationsSorted.first?.key
                if locationsSorted.count > 1 { storyTitle = storyTitle! + ", " + locationsSorted[1].key }
            }
            
            guard let title = storyTitle else { return }
            
            for component in locationComponents {
                if let locationItem = locations[component] {
                    locations[component] = locationItem + 1
                    continue
                }
                locations[component] = 1
            }
            
            // Minimum asset count
            guard totalAssetCount >= PhotobookSDK.shared.minimumRequiredPhotos else { return }
            
            let story = Story(list: list, storyTitle: title, coverCollection: moments.firstObject!)
            story.components = locationComponents
            story.photoCount = totalAssetCount
            
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
                        if orderedLocations.firstIndex(of: component)! <= Int(Double(component.count) * 0.2) {
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
        return location.components(separatedBy: CharacterSet(charactersIn: ",&")).map { (item) -> String in
                return item.trimmingCharacters(in: CharacterSet(charactersIn: " "))
            }.map { (item) -> String in
                if let range = item.range(of: " - ") {
                    return String(item.prefix(upTo: range.lowerBound))
                } else {
                    return item
                }
            }
    }    
}

extension StoriesManager: PHPhotoLibraryChangeObserver {
    
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        // We only care for the currently selected story
        guard let story = currentlySelectedStory else { return }
        
        var albumChanges = [AlbumChange]()
        
        DispatchQueue.main.sync {
            var assetsRemoved = [PhotobookAsset]()
            var indexesRemoved = [Int]()
            for asset in story.assets {
                guard let phAsset = asset.phAsset else { continue }
                if let changeDetails = changeInstance.changeDetails(for: phAsset), changeDetails.objectWasDeleted {
                    assetsRemoved.append(asset)
                    
                    if let index = story.assets.firstIndex(where: { $0 == asset }) {
                        indexesRemoved.append(index)
                    }
                }
            }
            albumChanges.append(AlbumChange(albumIdentifier: story.identifier, assetsRemoved: assetsRemoved, assetsInserted: [], indexesRemoved: indexesRemoved))
            
            // Remove assets from this story from the end as to not mess up the indexes
            for assetIndex in indexesRemoved.reversed() {
                story.assets.remove(at: assetIndex)
            }
            
            if !albumChanges.isEmpty {
                NotificationCenter.default.post(name: AlbumManagerNotificationName.albumsWereUpdated, object: albumChanges)
                PhotobookSDK.shared.albumsWereUpdated(albumChanges)
            }
        }
    }
    
}
