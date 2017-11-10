//
//  StoriesManager.swift
//  Photobook
//
//  Created by Jaime Landazuri on 09/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import Photos

class StoriesManager {
    
    // Shared client
    static let shared = StoriesManager()
    
    private let imageManager = PHImageManager.default()
    
    private struct Constants {
        static let photosPerBook = 20
    }
    
    func topStories(_ count: Int, completion: @escaping ([Story]?)->()) {
        PHPhotoLibrary.requestAuthorization { (status) in
            guard status == .authorized else {
                completion(nil)
                return
            }
            
            // Do the ordering asynchronously
            DispatchQueue.main.async {
                let memories = self.orderStories()
                completion(Array<Story>(memories.prefix(count)))
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
        momentLists.enumerateObjects { (list: PHCollectionList, index: Int, stop: UnsafeMutablePointer<ObjCBool>) in
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
            guard totalAssetCount > 20 else { return }
            
            let story = Story(list: list)
            story.components = locationComponents
            story.photoCount = totalAssetCount
            
            // Get cover
            let assetOptions = PHFetchOptions()
            assetOptions.fetchLimit = 1
            assetOptions.sortDescriptors = [ NSSortDescriptor(key: "creationDate", ascending: true) ]
            
            let photos = PHAsset.fetchAssets(in: moments.firstObject!, options: assetOptions)
            story.cover = photos.firstObject
            
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
                    // Is it a holiday?
                    
                    // Check if the locations are among the most visited
                    var hasCommonLocation = false
                    for component in story.components {
                        if orderedLocations.index(of: component)! <= Int(Double(component.count) * 0.2) {
                            hasCommonLocation = true
                            break
                        }
                    }
                    
                    let componentsHolidayCheck = NSCalendar.current.dateComponents([.day], from: startDate, to: endDate)
                    if componentsHolidayCheck.day! > 3 && componentsHolidayCheck.day! < 20  {
                        if !hasCommonLocation {
                            story.score += 20
                        } else {
                            story.score -= 10
                        }
                    } else if componentsHolidayCheck.day! <= 3 {
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
    
    func thumbnailForPhoto(_ photo: PHAsset, size: CGSize, completion: @escaping (UIImage?)->()) {
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        
        imageManager.requestImage(for: photo, targetSize: size, contentMode: .aspectFill, options: PHImageRequestOptions()) { (image, _) in
            completion(image)
        }
    }
    
    private func breakDownLocation(title location: String) -> [String] {
        if let mainLocation = location.index(of: "-") {
            return [ String(location.prefix(upTo: mainLocation)) ]
        }
        return location.components(separatedBy: CharacterSet(charactersIn: ",&")).map { (item) -> String in
            return item.trimmingCharacters(in: CharacterSet(charactersIn: " "))
        }
    }
}
