//
//  LayoutBox.swift
//  Photobook
//
//  Created by Jaime Landazuri on 20/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import Foundation
import UIKit

enum LayoutBoxType {
    case photo, text
}

// A bounding box for an image or text
struct LayoutBox {
    let id: Int!
    let type: LayoutBoxType!
    // Normalised origin value
    let origin: CGPoint!
    // Normalised  size value
    let size: CGSize!
    
//    init() {
//        fatalError("Use parse(_:) instead")
//    }
    
//    private init(id: Int, type: LayoutBoxType, origin: CGPoint, size: CGSize) {
//        self.id = id
//        self.type = type
//        self.origin = origin
//        self.size = size
//    }
    
    static func parse(_ layoutBoxDictionary: [String: AnyObject]) -> LayoutBox? {
        guard
            let id = layoutBoxDictionary["id"] as? Int,
            let contentTypeString = layoutBoxDictionary["contentType"] as? String,
            let dimensionsPercentages = layoutBoxDictionary["dimensionsPercentages"] as? [String: AnyObject],
            let width = dimensionsPercentages["width"] as? CGFloat, width.isNormalised,
            let height = dimensionsPercentages["height"] as? CGFloat, height.isNormalised,
            let relativeStartPoint = layoutBoxDictionary["relativeStartPoint"] as? [String: AnyObject],
            let x = relativeStartPoint["x"] as? CGFloat, x.isNormalised,
            let y = relativeStartPoint["y"] as? CGFloat, y.isNormalised
            else { return nil }
        
        var layoutBoxType: LayoutBoxType
        switch contentTypeString {
        case "image":
            layoutBoxType = .photo
        case "text":
            layoutBoxType = .text
        default:
            return nil
        }
        return LayoutBox(id: id, type: layoutBoxType, origin: CGPoint(x: x, y: y), size: CGSize(width: width, height: height))
    }
}
