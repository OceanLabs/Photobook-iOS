//
//  StoriesManager.swift
//  Photobook
//
//  Created by Jaime Landazuri on 09/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import Photos

class StoriesManager {
    
    enum StoriesManagerError: Error {
        case unauthorized
        case incompatibleAssetType
    }
    
    // Shared client
    static let shared = StoriesManager()
    
    private let imageManager = PHCachingImageManager()
    private var selectedAssetsManagerPerStory = [String : SelectedAssetsManager]()
    var stories = [Story]()
    
    private struct Constants {
        static let maxStoriesToDisplay = 16
    }
    
    func loadTopStories(){
        let memories = self.orderStories()
        stories = Array<Story>(memories.prefix(Constants.maxStoriesToDisplay))
        
        DispatchQueue.global(qos: .background).async {
            for story in self.stories {
                self.prepare(story: story, completionHandler: nil)
            }
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
                totalAssetCount += collection.estimatedAssetCount
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
    
    func prepare(story: Story, completionHandler: ((Error?) -> Void)?) {
        story.loadAssets(completionHandler: { [weak welf = self] error in
            welf?.performAutoSelection(on: story)
            completionHandler?(error)
            
            // Cache the first 25 thumbnails from each story so that they don't appear blank on the first animation
            // Not bulletproof, because the user might tap on a story before the assets finish caching
            guard !story.assets.isEmpty else { return }
            let imageWidth = UIScreen.main.bounds.size.width / 4.0
            welf?.imageManager.startCachingImages(for: PhotosAsset.photosAssets(from: Array(story.assets[0..<min(story.assets.count, 25)])), targetSize: CGSize(width: imageWidth, height: imageWidth), contentMode: .aspectFill, options: nil)
        })
    }
    
    func selectedAssetsManager(for story: Story) -> SelectedAssetsManager?{
        return selectedAssetsManagerPerStory[story.identifier]
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
    }
}
