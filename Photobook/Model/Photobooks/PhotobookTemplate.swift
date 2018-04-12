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
    var id: Int
    var name: String!
    var productTemplateId: String!
    var aspectRatio: CGFloat!
    var pageHeight: CGFloat!
    lazy var pageWidth: CGFloat! = { return pageHeight! * aspectRatio! }()
    var spineTextRatio: CGFloat!
    var coverLayouts: [Int]!
    var layouts: [Int]! // IDs of the permitted layouts
    
    // Does not include the cover asset
    var minimumRequiredAssets: Int! = 20 // TODO: Get this from somewhere
    
    // TODO: Currencies? MaximumAllowed Pages/Assets?
    
    init() {
        fatalError("Use parse(_:) instead")
    }
    
    private init(id: Int, name: String, productTemplateId: String, pageHeight: CGFloat, spineTextRatio: CGFloat, aspectRatio: CGFloat, coverLayouts: [Int], layouts: [Int]) {
        self.id = id
        self.name = name
        self.productTemplateId = productTemplateId
        self.pageHeight = pageHeight
        self.spineTextRatio = spineTextRatio
        self.aspectRatio = aspectRatio
        self.coverLayouts = coverLayouts
        self.layouts = layouts
    }

    // Parses a photobook dictionary.
    static func parse(_ dictionary: [String: AnyObject]) -> PhotobookTemplate? {
        
        guard
            let id = dictionary["id"] as? Int,
            let name = dictionary["name"] as? String,
            let productTemplateId = dictionary["productTemplateId"] as? String,
            let pageHeight = dictionary["pageHeight"] as? CGFloat, pageHeight > 0.0,
            let spineTextRatio = dictionary["spineTextRatio"] as? CGFloat, spineTextRatio > 0.0,
            let aspectRatio = dictionary["aspectRatio"] as? CGFloat, aspectRatio > 0.0,
            let coverLayouts = dictionary["coverLayouts"] as? [Int], !coverLayouts.isEmpty,
            let layouts = dictionary["layouts"] as? [Int], !layouts.isEmpty
        else { return nil }
        
        return PhotobookTemplate(id: id, name: name, productTemplateId: productTemplateId, pageHeight: pageHeight, spineTextRatio: spineTextRatio, aspectRatio: aspectRatio, coverLayouts: coverLayouts, layouts: layouts)
    }    
}
