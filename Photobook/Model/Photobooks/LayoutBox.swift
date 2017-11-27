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
struct LayoutBox {
    
    let id: Int!
    // Normalised origin value
    let origin: CGPoint!
    // Normalised  size value
    let size: CGSize!
    
    func isLandscape() -> Bool {
        return size.height > size.width
    }
    
    static func parse(_ layoutBoxDictionary: [String: AnyObject]) -> LayoutBox? {
        guard
            let id = layoutBoxDictionary["id"] as? Int,
            let dimensionsPercentages = layoutBoxDictionary["dimensionsPercentages"] as? [String: AnyObject],
            let width = dimensionsPercentages["width"] as? CGFloat, width.isNormalised,
            let height = dimensionsPercentages["height"] as? CGFloat, height.isNormalised,
            let relativeStartPoint = layoutBoxDictionary["relativeStartPoint"] as? [String: AnyObject],
            let x = relativeStartPoint["x"] as? CGFloat, x.isNormalised,
            let y = relativeStartPoint["y"] as? CGFloat, y.isNormalised
            else { return nil }
        
        return LayoutBox(id: id, origin: CGPoint(x: x, y: y), size: CGSize(width: width, height: height))
    }
}
