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
    var productId: Int
    var variantId: String!
    var name: String!
    var pageSizeRatio: CGFloat! // FIXME: This is the spread size ratio atm but should eventually be for a page
    var layouts: [Layout]!
    
    init() {
        fatalError("Use init(id:name:pageSizeRatio:) instead")
    }
    
    init(productId: Int, variantId: String, name: String, pageSizeRatio: CGFloat) {
        self.productId = productId
        self.variantId = variantId
        self.name = name
        self.pageSizeRatio = pageSizeRatio
    }
    
    // Parses a photobook dictionary.
    // There's a 1-to-1 relation between photobook
    static func parse(dictionary: [String: AnyObject]) -> Photobook? {
        
        guard
            let productId = dictionary["id"] as? Int,
            let name = dictionary["name"] as? String,
            let variants = dictionary["variants"] as? [[String: AnyObject]],
            let variant = variants.first,
            let variantId = variant["id"] as? String
        else { return nil }
        
        var pageSizeRatio: CGFloat = 1.0
        if let pageWidth = variant["pageWidth"] as? CGFloat, let pageHeight = variant["pageHeight"] as? CGFloat {
            pageSizeRatio = pageWidth / pageHeight
        }
        
        return Photobook(productId: productId, variantId: variantId, name: name, pageSizeRatio: pageSizeRatio)
    }
    
    func parseLayouts(from layouts: [[String: AnyObject]]) {
        
        var tempLayouts = [Layout]()
        
        for layoutDictionary in layouts {
            if let layout = Layout.parse(layoutDictionary) {
                tempLayouts.append(layout)
            }
        }
        
        self.layouts = tempLayouts
    }
}
