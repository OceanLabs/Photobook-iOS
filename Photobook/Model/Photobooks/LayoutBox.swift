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
    let type: LayoutBoxType!
    let normalisedSize: CGSize!
    let normalisedOrigin: CGPoint!
    
    static func parse(_ layoutBoxDictionary: [String: AnyObject]) -> LayoutBox? {
        guard
            let contentTypeString = layoutBoxDictionary["contentType"] as? String,
            let dimensionsPercentages = layoutBoxDictionary["dimensionsPercentages"] as? [String: AnyObject],
            let width = dimensionsPercentages["width"] as? CGFloat,
            let height = dimensionsPercentages["height"] as? CGFloat,
            let relativeStartPoint = layoutBoxDictionary["relativeStartPoint"] as? [String: AnyObject],
            let x = relativeStartPoint["x"] as? CGFloat,
            let y = relativeStartPoint["y"] as? CGFloat
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
        
        return LayoutBox(type: layoutBoxType, normalisedSize: CGSize(width: width / 100.0, height: height / 100.0), normalisedOrigin: CGPoint(x: x / 100.0, y: y / 100.0))
    }
}
