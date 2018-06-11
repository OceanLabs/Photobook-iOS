//
//  PhotobookTemplate.swift
//  Photobook
//
//  Created by Jaime Landazuri on 17/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import Foundation
import UIKit

// Defines the characteristics of a photobook / product
class PhotobookTemplate: Codable {
    
    private static let mmToPtMultiplier = 2.83464566929134
    
    var id: Int
    var name: String
    var templateId: String
    var kiteId: String
    var coverSize: CGSize
    var pageSize: CGSize
    var coverAspectRatio: CGFloat { return coverSize.width / coverSize.height }
    var pageAspectRatio: CGFloat { return pageSize.width / pageSize.height }
    var spineTextRatio: CGFloat
    var coverLayouts: [Int]
    var layouts: [Int] // IDs of the permitted layouts
    var minPages: Int = 20
    var maxPages: Int = 100
    
    // TODO: Currencies?
    
    init(id: Int, name: String, templateId: String, kiteId: String, coverSize: CGSize, pageSize: CGSize, spineTextRatio: CGFloat, coverLayouts: [Int], layouts: [Int]) {
        self.id = id
        self.name = name
        self.templateId = templateId
        self.kiteId = kiteId
        self.coverSize = coverSize
        self.pageSize = pageSize
        self.spineTextRatio = spineTextRatio
        self.coverLayouts = coverLayouts
        self.layouts = layouts
    }

    // Parses a photobook dictionary.
    static func parse(_ dictionary: [String: AnyObject]) -> PhotobookTemplate? {
        
        guard
            let id = dictionary["id"] as? Int,
            let name = dictionary["displayName"] as? String,
            let spineTextRatio = dictionary["spineTextRatio"] as? Double, spineTextRatio > 0.0,
            let coverLayouts = dictionary["coverLayouts"] as? [Int], !coverLayouts.isEmpty,
            let layouts = dictionary["layouts"] as? [Int], !layouts.isEmpty,

            let variantDictionary = (dictionary["variants"] as? [[String: AnyObject]])?.first,
        
            let kiteId = variantDictionary["kiteId"] as? String,
            let templateId = variantDictionary["templateId"] as? String,
            let coverSizeDictionary = variantDictionary["coverSize"] as? [String: Any],
            let coverSizeMm = coverSizeDictionary["mm"] as? [String: Any],
            let coverWidth = coverSizeMm["width"] as? Double,
            let coverHeight = coverSizeMm["height"] as? Double,
            
            let pageSizeDictionary = variantDictionary["size"] as? [String: Any],
            let pageSizeMm = pageSizeDictionary["mm"] as? [String: Any],
            let pageWidth = pageSizeMm["width"] as? Double,
            let pageHeight = pageSizeMm["height"] as? Double
        else { return nil }
        
        let coverSize = CGSize(width: coverWidth * PhotobookTemplate.mmToPtMultiplier, height: coverHeight * PhotobookTemplate.mmToPtMultiplier)
        let pageSize = CGSize(width: pageWidth * PhotobookTemplate.mmToPtMultiplier * 0.5, height: pageHeight * PhotobookTemplate.mmToPtMultiplier) // The width is that of a full spread
        
        let photobookTemplate = PhotobookTemplate(id: id, name: name, templateId: templateId, kiteId: kiteId, coverSize: coverSize, pageSize: pageSize, spineTextRatio: CGFloat(spineTextRatio), coverLayouts: coverLayouts, layouts: layouts)

        if let minPages = variantDictionary["minPages"] as? Int { photobookTemplate.minPages = minPages }
        if let maxPages = variantDictionary["maxPages"] as? Int { photobookTemplate.maxPages = maxPages }
        
        return photobookTemplate
    }    
}

extension PhotobookTemplate: Equatable {
    
    static func ==(lhs: PhotobookTemplate, rhs: PhotobookTemplate) -> Bool {
        return lhs.id == rhs.id
    }
}
