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
class Photobook: Codable {
    var id: Int
    var name: String!
    var pageHeight: CGFloat!
    var aspectRatio: CGFloat!
    var coverLayouts: [Int]!
    var layouts: [Int]! // IDs of the permitted layouts
    
    // Does not include the cover asset
    var minimumRequiredAssets: Int! = 20 // TODO: Get this from somewhere
    
    // TODO: Currencies? MaximumAllowed Pages/Assets?
    
    init() {
        fatalError("Use parse(_:) instead")
    }
    
    private init(id: Int, name: String, pageHeight: CGFloat, aspectRatio: CGFloat, coverLayouts: [Int], layouts: [Int]) {
        self.id = id
        self.name = name
        self.pageHeight = pageHeight
        self.aspectRatio = aspectRatio
        self.coverLayouts = coverLayouts
        self.layouts = layouts
    }

    // Parses a photobook dictionary.
    static func parse(_ dictionary: [String: AnyObject]) -> Photobook? {
        
        guard
            let id = dictionary["id"] as? Int,
            let name = dictionary["name"] as? String,
            let pageHeight = dictionary["pageHeight"] as? CGFloat, pageHeight > 0.0,
            let aspectRatio = dictionary["aspectRatio"] as? CGFloat, aspectRatio > 0.0,
            let coverLayouts = dictionary["coverLayouts"] as? [Int], !coverLayouts.isEmpty,
            let layouts = dictionary["layouts"] as? [Int], !layouts.isEmpty
        else { return nil }
        
        return Photobook(id: id, name: name, pageHeight: pageHeight, aspectRatio: aspectRatio, coverLayouts: coverLayouts, layouts: layouts)
    }    
}
