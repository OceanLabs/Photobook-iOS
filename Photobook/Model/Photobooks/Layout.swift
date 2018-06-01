//
//  Layout.swift
//  Photobook
//
//  Created by Jaime Landazuri on 20/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import Foundation

// Information about a page layout
struct Layout: Equatable, Codable {
    let id: Int!
    let category: String!
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
            let category = layoutDictionary["category"] as? String
            else { return nil }
        
        var layout = Layout(id: id, category: category, imageLayoutBox: nil, textLayoutBox: nil, isDoubleLayout: false)
        
        if let layoutBoxesDictionary = layoutDictionary["layoutBoxes"] as? [[String: AnyObject]] {
            for layoutBoxDictionary in layoutBoxesDictionary {
                guard let type = layoutBoxDictionary["type"] as? String else { continue }
                
                if type == "image" { layout.imageLayoutBox = LayoutBox.parse(layoutBoxDictionary) }
                else if type == "text" { layout.textLayoutBox = LayoutBox.parse(layoutBoxDictionary) }
            }
        }
        
        // TEMP: Avoid parsing double layouts as the PDF generation does not support them
        if let doubleLayout = layoutDictionary["isDoublePage"] as? Bool, doubleLayout {
            return nil
        }
        
        return layout
    }
    
    static func ==(lhs: Layout, rhs: Layout) -> Bool {
        return lhs.id == rhs.id && lhs.category == rhs.category
    }
}
