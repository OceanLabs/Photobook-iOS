//
//  Layout.swift
//  Photobook
//
//  Created by Jaime Landazuri on 20/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import Foundation

// Information about a double-spread
struct Layout {
    let id: Int!
    let name: String!
    let imageUrl: String!
    let layoutBoxes: [LayoutBox]!
    
    static func parse(_ layoutDictionary: [String: AnyObject]) -> Layout? {
        guard
            let id = layoutDictionary["id"] as? Int,
            let name = layoutDictionary["name"] as? String,
            let imageUrlString = layoutDictionary["imageUrl"] as? String,
            !imageUrlString.isEmpty,
            let escapedImageUrlString = imageUrlString.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
            let _ = URL(string: "https://test.com" + escapedImageUrlString), // Check if creating a URL from this string is possible
            let layoutBoxesDictionary = layoutDictionary["layoutBoxes"] as? [[String: AnyObject]]
            else { return nil }
        
        var tempLayoutBoxes = [LayoutBox]()
        for layoutBoxDictionary in layoutBoxesDictionary {
            if let layoutBox = LayoutBox.parse(layoutBoxDictionary) {
                tempLayoutBoxes.append(layoutBox)
            }
        }
        
        return Layout(id: id, name: name, imageUrl: imageUrlString, layoutBoxes: tempLayoutBoxes)
    }
}
