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
        return rect.width > rect.height
    }
    
    func rectContained(in size: CGSize) -> CGRect {
        let x = rect.minX * size.width
        let y = rect.minY * size.height
        let width = rect.width * size.width
        let height = rect.height * size.height
        return CGRect(x: x, y: y, width: width, height: height)
    }
    
    func aspectRatio(forContainerRatio ratio: CGFloat) -> CGFloat {
        let containerWidth: CGFloat = 1000.0
        let containerHeight = containerWidth / ratio
        
        let width = containerWidth * rect.width
        let height = containerHeight * rect.height
        return width / height
    }
    
    func containerSize(for size: CGSize) -> CGSize {
        let width = size.width / rect.width
        let height = size.height / rect.height
        return CGSize(width: width, height: height)
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
}
