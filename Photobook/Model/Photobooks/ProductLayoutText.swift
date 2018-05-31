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
    var containerSize: CGSize!
    var text: String?
    var htmlText: String?
    var fontType: FontType = .plain
    
    func deepCopy() -> ProductLayoutText {
        let aLayoutText = ProductLayoutText()
        aLayoutText.text = text
        aLayoutText.htmlText = htmlText
        aLayoutText.fontType = fontType
        aLayoutText.containerSize = containerSize
        return aLayoutText
    }
}
