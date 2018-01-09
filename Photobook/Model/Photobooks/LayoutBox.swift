//
//  LayoutBox.swift
//  Photobook
//
//  Created by Jaime Landazuri on 20/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import Foundation
import UIKit

// A bounding box for an image or text
struct LayoutBox: Codable {
    
    let id: Int!
    // Normalised rect
    let rect: CGRect!
    
    func isLandscape() -> Bool {
        return rect.height > rect.width
    }
    
    static func parse(_ layoutBoxDictionary: [String: AnyObject]) -> LayoutBox? {
        guard
            let id = layoutBoxDictionary["id"] as? Int,
            let rectDictionary = layoutBoxDictionary["rect"] as? [String: AnyObject],
            let x = rectDictionary["x"] as? CGFloat, x.isNormalised,
            let y = rectDictionary["y"] as? CGFloat, y.isNormalised,
            let width = rectDictionary["width"] as? CGFloat, width.isNormalised,
            let height = rectDictionary["height"] as? CGFloat, height.isNormalised
            else { return nil }
        
        return LayoutBox(id: id, rect: CGRect(x: x, y: y, width: width, height: height))
    }
    
    func rectContained(in size: CGSize) -> CGRect {
        let x = rect.minX * size.width
        let y = rect.minY * size.height
        let width = rect.width * size.width
        let height = rect.height * size.height
        return CGRect(x: x, y: y, width: width, height: height)
    }
}
