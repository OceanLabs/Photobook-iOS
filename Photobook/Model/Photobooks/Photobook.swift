//
//  Photobook.swift
//  Photobook
//
//  Created by Jaime Landazuri on 17/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import Foundation
import UIKit

// Defines the characteristics of a photobook / product
class Photobook {
    var id: Int
    var name: String!
    var coverSizeRatio: CGFloat!
    var pageSizeRatio: CGFloat!
    var baseCost: Decimal!
    var costPerPage: Decimal!
    var layouts: [Int]! // IDs of the permitted layouts
    
    // FIXME: Min pages? Currencies?
    
    init() {
        fatalError("Use parse(_:) instead")
    }
    
    private init(id: Int, name: String, coverSizeRatio: CGFloat, pageSizeRatio: CGFloat, baseCost: Decimal, costPerPage: Decimal, layouts: [Int]) {
        self.id = id
        self.name = name
        self.coverSizeRatio = coverSizeRatio
        self.pageSizeRatio = pageSizeRatio
        self.baseCost = baseCost
        self.costPerPage = costPerPage
        self.layouts = layouts
    }

    // Parses a photobook dictionary.
    static func parse(_ dictionary: [String: AnyObject]) -> Photobook? {
        
        guard
            let id = dictionary["id"] as? Int,
            let name = dictionary["name"] as? String,
            let pageWidth = dictionary["pageWidth"] as? CGFloat,
            let pageHeight = dictionary["pageHeight"] as? CGFloat,
            pageWidth > 0.0, pageHeight > 0.0,
            let coverWidth = dictionary["coverWidth"] as? CGFloat,
            let coverHeight = dictionary["coverHeight"] as? CGFloat,
            coverWidth > 0.0, coverHeight > 0.0,
            let costDictionary = dictionary["cost"] as? [String: AnyObject],
            let costPerPageDictionary = dictionary["costPerPage"] as? [String: AnyObject],
            let baseCost = costDictionary["GBP"] as? Double,
            let costPerPage = costPerPageDictionary["GBP"] as? Double,
            let layouts = dictionary["layouts"] as? [Int],
            layouts.count > 0
        else { return nil }
        
        let coverSizeRatio = coverWidth / coverHeight
        let pageSizeRatio = pageWidth / pageHeight

        return Photobook(id: id, name: name, coverSizeRatio: coverSizeRatio, pageSizeRatio: pageSizeRatio, baseCost: Decimal(baseCost), costPerPage: Decimal(costPerPage), layouts: layouts)
    }
}
