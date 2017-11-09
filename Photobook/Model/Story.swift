//
//  Story.swift
//  Photobook
//
//  Created by Jaime Landazuri on 09/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import Photos

class Story {
    let collectionList: PHCollectionList
    var cover: PHAsset!
    var components: [String]!
    var photoCount = 0
    var isHoliday = false
    var isWeekend = false
    var score = 0
    
    var title: String {
        return collectionList.localizedTitle!.uppercased()
    }
    
    lazy var subtitle: String? = {
        if self.isWeekend { return ("Weekend in " + dateString()).uppercased() }
        if self.isHoliday { return (dateString() + " Trip").uppercased() }
        return dateString().uppercased()
    }()
    
    init(list: PHCollectionList) {
        collectionList = list
    }
    
    private func dateString() -> String {
        guard let startDate = collectionList.startDate, let endDate = collectionList.endDate else { return "" }
        
        let dateFormatter = DateFormatter()
        
        // Check if it's same day
        if NSCalendar.current.isDate(startDate, inSameDayAs: endDate) {
            dateFormatter.dateFormat = "dd MMM yyyy"
            
            return dateFormatter.string(from: startDate)
        }
        
        let startDateComponents = NSCalendar.current.dateComponents([.day, .month, .year], from: startDate)
        let endDateComponents = NSCalendar.current.dateComponents([.day, .month, .year], from: endDate)
        
        // Different years
        if startDateComponents.year != endDateComponents.year {
            dateFormatter.dateFormat = "yyyy"
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


