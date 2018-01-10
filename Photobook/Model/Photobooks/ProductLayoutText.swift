//
//  ProductLayoutText.swift
//  Photobook
//
//  Created by Jaime Landazuri on 24/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import Foundation
import UIKit

// A photo item in the user's photobook assigned to a layout box
class ProductLayoutText: Codable {
    var containerSize: CGSize! {
        didSet {
            // TODO: Apply text limitations
        }
    }
    var text: String?
    
    func shallowCopy() -> ProductLayoutText {
        let aLayoutText = ProductLayoutText()
        aLayoutText.text = text?.copy() as? String
        aLayoutText.containerSize = containerSize
        return aLayoutText
    }
}
