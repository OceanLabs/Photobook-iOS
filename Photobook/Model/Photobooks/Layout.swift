//
//  Layout.swift
//  Photobook
//
//  Created by Jaime Landazuri on 20/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import Foundation

// Information about a page layout
struct Layout {
    let id: Int!
    let category: Int!
    let imageUrl: String!
    var imageLayoutBox: LayoutBox?
    var textLayoutBox: LayoutBox?
    var isDoubleLayout: Bool = false
    
    func isEmptyLayout() -> Bool {
        return imageLayoutBox == nil && textLayoutBox == nil
    }
    
    func isLandscape() -> Bool {
        return imageLayoutBox != nil ? imageLayoutBox!.isLandscape() : false
    }
    
    static func parse(_ layoutDictionary: [String: AnyObject]) -> Layout? {
        guard
            let id = layoutDictionary["id"] as? Int,
            let category = layoutDictionary["category"] as? Int,
            let imageUrlString = layoutDictionary["imageUrl"] as? String,
            !imageUrlString.isEmpty,
            !imageUrlString.lowercased().hasPrefix("http"),
            let escapedImageUrlString = imageUrlString.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
            let _ = URL(string: "https://test.com" + escapedImageUrlString) // Check if creating a URL from this string is possible
            else { return nil }
        
        var layout = Layout(id: id, category: category, imageUrl: imageUrlString, imageLayoutBox: nil, textLayoutBox: nil, isDoubleLayout: false)
        
        if let imageLayoutBoxDictionary = layoutDictionary["imageLayoutBox"] as? [String: AnyObject] {
            layout.imageLayoutBox = LayoutBox.parse(imageLayoutBoxDictionary)
        }
        if let textLayoutBoxDictionary = layoutDictionary["textLayoutBox"] as? [String: AnyObject] {
            layout.textLayoutBox = LayoutBox.parse(textLayoutBoxDictionary)
        }
        if let doubleLayout = layoutDictionary["doubleLayout"] as? Bool {
            layout.isDoubleLayout = doubleLayout
        }
        
        return layout
    }
}
